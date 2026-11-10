import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:perfume_dex/widgets/nearby_stores/store_details_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/map_config.dart';
import '../../models/nearby_store.dart';
import '../../models/user_profile.dart';
import '../../services/map_services/distance_ranking/distance_ranking.dart';
import '../../services/map_services/location_service.dart';
import '../../services/map_services/nearby_stores_service.dart';
import '../../services/users_service.dart';
import 'blurred_map_placeholder.dart';
import 'nearby_stores_list.dart';
import 'stores_map.dart';

/// En qué punto está la sección.
enum _Status {
  idle, // aún no se ha buscado: placeholder + botón
  loading, // pidiendo ubicación y buscando tiendas
  loaded, // hay tiendas: mapa real
  empty, // búsqueda correcta, pero ninguna tienda en 40 km
  error, // falló la ubicación o la red
}

/// Sección "Perfumerías cerca de ti" de la ficha de un perfume.
///
/// No pinta nada propio: decide, según el estado, si mostrar el
/// [BlurredMapPlaceholder] (con botón, spinner o mensaje encima) o el
/// [StoresMap] con los resultados.
class NearbyStoresSection extends StatefulWidget {
  const NearbyStoresSection({super.key});

  @override
  State<NearbyStoresSection> createState() => _NearbyStoresSectionState();
}

class _NearbyStoresSectionState extends State<NearbyStoresSection> {
  static const _locationService = LocationService();
  final NearbyStoresService _storesService = NearbyStoresService.instance;
  final UsersService _usersService = UsersService();

  _Status _status = _Status.idle;
  NearbyStoresResult? _result;

  // Por qué falló la ubicación. Si el estado es error y esto es null, el
  // fallo fue de red (la búsqueda de tiendas), no de ubicación.
  LocationFailure? _failure;

  // Zona de la última búsqueda guardada en el perfil. Solo se lee del
  // perfil cuando falla la ubicación, para ofrecerla como alternativa.
  GeoPoint? _savedZone;
  DateTime? _savedZoneAt;

  // Lista "cerca de ti": tiendas ordenadas por distancia (null mientras se
  // calcula) y progreso del cálculo, de 0 a 1.
  List<RankedStore>? _ranked;
  double? _rankingProgress;

  @override
  void initState() {
    super.initState();
    // Si ya se buscó en esta sesión (en este u otro perfume), se reutiliza
    // sin pedir nada: ni permiso, ni ubicación, ni red.
    final cached = _storesService.cached;
    if (cached != null) {
      _result = cached;
      _status = _statusFor(cached);
      _startRanking(cached);
    }
  }

  /// Prepara la lista y lanza el cálculo de distancias sin esperarlo.
  /// Se llama dentro de un setState (o en initState), así que solo cambia
  /// campos: los setState los hace _rankStores cuando hay novedades.
  void _startRanking(NearbyStoresResult result) {
    _ranked = null;
    _rankingProgress = 0;
    unawaited(_rankStores(result));
  }

  /// Ordena las tiendas por distancia al usuario (en un isolate en Android)
  /// y va actualizando la barra de progreso.
  Future<void> _rankStores(NearbyStoresResult result) async {
    try {
      final ranking = await rankByDistance(
        result.userPosition,
        result.stores,
        onProgress: (progress) {
          // Si mientras tanto llegó otra búsqueda, este progreso ya no vale.
          if (!mounted || _result != result) return;
          setState(() {
            _rankingProgress = progress;
          });
        },
      );

      final where = ranking.usedIsolate ? 'isolate' : 'hilo principal';
      debugPrint('${result.stores.length} tiendas ordenadas en '
          '${ranking.elapsed.inMicroseconds} µs ($where)');

      if (!mounted || _result != result) return;
      setState(() {
        _ranked = ranking.stores;
        _rankingProgress = null;
      });
    } catch (e) {
      debugPrint('No se pudieron ordenar las tiendas: $e');
      if (!mounted || _result != result) return;
      // Plan B: el orden y las distancias que ya calculó el servidor.
      final fallback = <RankedStore>[];
      for (final store in result.stores) {
        fallback.add((store: store, distanceKm: store.distanceKm));
      }
      setState(() {
        _ranked = fallback;
        _rankingProgress = null;
      });
    }
  }

  _Status _statusFor(NearbyStoresResult result) {
    if (result.stores.isEmpty) {
      return _Status.empty;
    }
    return _Status.loaded;
  }

  /// Busca alrededor de la posición actual del dispositivo.
  Future<void> _search() async {
    setState(() {
      _status = _Status.loading;
      _failure = null;
    });

    final LatLng position;
    try {
      position = await _locationService.getCurrentPosition();
    } on LocationException catch (e) {
      // Sin posición: miramos si el perfil guarda una zona que ofrecer.
      // La variable se declara fuera del try para poder usarla después.
      UserProfile? profile;
      try {
        // Sin red, la lectura del perfil puede tardar bastante en rendirse.
        // Con el timeout, el mensaje de error sale como mucho en 5 s.
        profile = await _usersService
            .getCurrentUserProfile()
            .timeout(const Duration(seconds: 5));
      } catch (error) {
        // Si no se puede leer el perfil, se muestra el error de ubicación
        // sin ofrecer la zona guardada (profile se queda en null).
        debugPrint('No se pudo leer la zona guardada: $error');
      }
      // Mientras esperábamos, el usuario pudo salir de la pantalla.
      if (!mounted) return;
      setState(() {
        _failure = e.failure;
        _savedZone = profile?.lastSearchLocation;
        _savedZoneAt = profile?.lastSearchAt;
        _status = _Status.error;
      });
      return;
    }

    await _searchAt(position, saveZone: true);
  }

  /// Busca alrededor de la zona guardada en el perfil.
  Future<void> _searchSavedZone() async {
    final zone = _savedZone;
    if (zone == null) return;

    setState(() {
      _status = _Status.loading;
      _failure = null;
    });
    // saveZone: false → no se vuelve a guardar la misma zona con fecha nueva,
    // como si el usuario hubiera estado allí ahora.
    await _searchAt(LatLng(zone.latitude, zone.longitude), saveZone: false);
  }

  /// Busca tiendas alrededor de [position] y, si [saveZone], guarda la zona
  /// en el perfil.
  Future<void> _searchAt(LatLng position, {required bool saveZone}) async {
    try {
      final result = await _storesService.search(position);
      if (saveZone) {
        // unawaited: no esperamos a que se guarde para enseñar el mapa.
        unawaited(_saveZone(position, result));
      }
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = _statusFor(result);
        _startRanking(result);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = null;
        _status = _Status.error;
      });
    }
  }

  /// Guarda la zona en el perfil. Si falla (sin sesión, sin red...), la
  /// búsqueda ya se ha hecho igualmente: solo se registra el error.
  Future<void> _saveZone(LatLng position, NearbyStoresResult result) async {
    // Nombre de la zona: la ciudad de la tienda más cercana (la primera, ya
    // que vienen ordenadas). firstOrNull da null si no hay ninguna tienda.
    final area = result.stores.firstOrNull?.city;
    try {
      await _usersService.saveLastSearchLocation(
        position.latitude,
        position.longitude,
        area: area,
      );
    } catch (e) {
      debugPrint('No se pudo guardar la zona de búsqueda: $e');
    }
  }

  // Abre la ficha de la tienda seleccionada
  void _openStore(NearbyStore store) {
    showStoreDetailsSheet(context, store);
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _status == _Status.loaded || _status == _Status.empty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Perfumerías cerca de ti",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (hasResult)
                IconButton(
                  tooltip: 'Volver a buscar',
                  icon: const Icon(Icons.refresh),
                  onPressed: _search,
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildContent(),
            ),
          ),
          if (hasResult) ...[
            const SizedBox(height: 8),
            // Pie: datos de la búsqueda a la izquierda y, si se ve el mapa,
            // la atribución de las teselas a la derecha. Los dos textos
            // pueden partirse en dos líneas si no caben en un móvil estrecho.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _footerText(_result!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                if (_status == _Status.loaded) ...[
                  const SizedBox(width: 12),
                  Expanded( //Expanded para que ocupe el ancho disponible
                    child: GestureDetector(
                      onTap: () => launchUrl(Uri.parse(MapConfig.attributionUrl)),
                      child: Text(
                        '© ${MapConfig.attributionText}',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Lista "cerca de ti", debajo del mapa.
          if (_status == _Status.loaded) ...[
            const SizedBox(height: 12),
            NearbyStoresList(
              stores: _ranked,
              progress: _rankingProgress,
              onStoreTap: _openStore,
            ),
          ],
        ],
      ),
    );
  }

  /// Lo que va dentro del recuadro de 220 px según el estado.
  Widget _buildContent() {
    switch (_status) {
      case _Status.idle:
        return BlurredMapPlaceholder(
          child: FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text(
              'Ver perfumerías cercanas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );

      case _Status.loading:
        return const BlurredMapPlaceholder(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Buscando perfumerías…'),
            ],
          ),
        );

      case _Status.loaded:
        return StoresMap(result: _result!, onStoreTap: _openStore);

      case _Status.empty:
        return BlurredMapPlaceholder(
          child: _Message(
            text: 'No hay perfumerías a menos de ${_result!.radiusKm} km.',
          ),
        );

      case _Status.error:
        final error = _errorInfo();
        final zoneAt = _savedZoneAt;

        // Falló la ubicación (no la red) y hay zona guardada: se ofrece como
        // acción principal, y la de siempre pasa a ser la secundaria.
        if (_failure != null && _savedZone != null && zoneAt != null) {
          return BlurredMapPlaceholder(
            child: _Message(
              text: '${error.message}\n'
                  '¿Quieres usar tu última zona de búsqueda (${_agoText(zoneAt)})?',
              actionLabel: 'Usar última zona',
              onAction: _searchSavedZone,
              secondaryLabel: error.actionLabel,
              onSecondary: error.onAction,
            ),
          );
        }

        return BlurredMapPlaceholder(
          child: _Message(
            text: error.message,
            actionLabel: error.actionLabel,
            onAction: error.onAction,
          ),
        );
    }
  }

  /// "hace 5 min", "hace 3 h", "hace 2 días".
  String _agoText(DateTime at) {
    final age = DateTime.now().difference(at);
    if (age.inMinutes == 0){
      return "hace un momento";
    }
    else if(age.inMinutes < 60){
      return "hace ${age.inMinutes} min";
    }
    else if(age.inHours < 24){
      return "hace ${age.inHours} h";
    }
    else if(age.inDays == 1){
      return "hace 1 día";
    }
    else {
      return "hace ${age.inDays} días";
    }
  }

  /// Texto y botón para cada tipo de error.
  ({String message, String actionLabel, VoidCallback onAction}) _errorInfo() {
    switch (_failure) {
      case LocationFailure.serviceDisabled:
        if (kIsWeb) {
          return (
            message: 'La ubicación del dispositivo está desactivada.',
            actionLabel: 'Reintentar',
            onAction: _search,
          );
        }
        return (
          message: 'La ubicación del dispositivo está desactivada.',
          actionLabel: 'Activar ubicación',
          onAction: _locationService.openLocationSettings,
        );

      case LocationFailure.deniedForever:
        // En web no hay ajustes de la app que abrir: el permiso se cambia
        // desde el candado de la barra de direcciones.
        if (kIsWeb) {
          return (
            message: 'Permite la ubicación desde el candado de la barra de direcciones.',
            actionLabel: 'Reintentar',
            onAction: _search,
          );
        }
        return (
          message: 'El permiso de ubicación fue bloqueado.',
          actionLabel: 'Abrir ajustes',
          onAction: _locationService.openAppSettings,
        );

      case LocationFailure.denied:
        return (
          message: 'Necesitamos tu ubicación para buscar perfumerías.',
          actionLabel: 'Permitir',
          onAction: _search,
        );

      case LocationFailure.timeout:
        return (
          message: 'Tu ubicación está tardando demasiado en llegar.',
          actionLabel: 'Reintentar',
          onAction: _search,
        );

      case LocationFailure.unavailable:
        return (
          message: 'No hemos podido obtener tu ubicación.',
          actionLabel: 'Reintentar',
          onAction: _search,
        );

      case null:
        return (
          message: 'No hemos podido buscar perfumerías.',
          actionLabel: 'Reintentar',
          onAction: _search,
        );
    }
  }

  /// "Radio de 10 km · actualizado hace 5 min"
  String _footerText(NearbyStoresResult result) {
    final minutes = result.age.inMinutes;
    String updated;
    if (minutes < 1) {
      updated = 'actualizado ahora mismo';
    } else {
      updated = 'actualizado hace $minutes min';
    }
    return 'Radio de ${result.radiusKm} km · $updated';
  }
}

/// Mensaje centrado con hasta dos botones debajo: uno principal (relleno)
/// y otro secundario (con borde).
class _Message extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _Message({
    required this.text,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    // Copias locales para que Dart pueda promocionarlas a no-null.
    final label = actionLabel;
    final action = onAction;
    final secondLabel = secondaryLabel;
    final secondAction = onSecondary;

    final buttons = <Widget>[];
    if (label != null && action != null) {
      buttons.add(FilledButton(onPressed: action, child: Text(label)));
    }
    if (secondLabel != null && secondAction != null) {
      buttons.add(OutlinedButton(onPressed: secondAction, child: Text(secondLabel)));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Wrap: los botones van en fila y, si no caben, bajan a otra línea.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: buttons,
            ),
          ],
        ],
      ),
    );
  }
}
