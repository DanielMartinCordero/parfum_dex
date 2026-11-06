import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../models/nearby_store.dart';
import '../../services/map_services/location_service.dart';
import '../../services/map_services/nearby_stores_service.dart';
import 'blurred_map_placeholder.dart';
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

  _Status _status = _Status.idle;
  NearbyStoresResult? _result;

  // Por qué falló la ubicación. Si el estado es error y esto es null, el
  // fallo fue de red (la búsqueda de tiendas), no de ubicación.
  LocationFailure? _failure;

  @override
  void initState() {
    super.initState();
    // Si ya se buscó en esta sesión (en este u otro perfume), se reutiliza
    // sin pedir nada: ni permiso, ni ubicación, ni red.
    final cached = _storesService.cached;
    if (cached != null) {
      _result = cached;
      _status = _statusFor(cached);
    }
  }

  _Status _statusFor(NearbyStoresResult result) {
    if (result.stores.isEmpty) {
      return _Status.empty;
    }
    return _Status.loaded;
  }

  Future<void> _search() async {
    setState(() {
      _status = _Status.loading;
      _failure = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final result = await _storesService.search(position);
      // Mientras esperábamos, el usuario pudo salir de la pantalla.
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = _statusFor(result);
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = e.failure;
        _status = _Status.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = null;
        _status = _Status.error;
      });
    }
  }

  // Provisional: lo sustituirá la ficha de la tienda (bottom sheet).
  void _openStore(NearbyStore store) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(store.chain)),
    );
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
            Text(
              _footerText(_result!),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        return BlurredMapPlaceholder(
          child: _Message(
            text: error.message,
            actionLabel: error.actionLabel,
            onAction: error.onAction,
          ),
        );
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

/// Mensaje centrado con un botón opcional debajo.
class _Message extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    // Copias locales para que Dart pueda promocionarlas a no-null.
    final label = actionLabel;
    final action = onAction;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (label != null && action != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: action, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
