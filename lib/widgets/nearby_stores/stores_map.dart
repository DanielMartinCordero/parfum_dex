import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/map_config.dart';
import '../../models/nearby_store.dart';

/// Mapa real (flutter_map + teselas de OpenStreetMap) con la posición del
/// usuario y las perfumerías encontradas, numeradas de la más cercana a la
/// más lejana.
///
/// Igual que el placeholder, no decide su tamaño: el padre le da la altura.
class StoresMap extends StatelessWidget {
  final NearbyStoresResult result;

  // Qué hacer al pulsar una tienda. El mapa no sabe abrir la ficha: se lo
  // delega a quien lo usa (la sección), que es quien decide qué mostrar.
  final void Function(NearbyStore store) onStoreTap;

  const StoresMap({
    super.key,
    required this.result,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    // Puntos que tienen que quedar a la vista al abrir el mapa.
    final visiblePoints = <LatLng>[result.userPosition];
    for (final store in result.stores) {
      visiblePoints.add(store.point);
    }

    // El punto del usuario va primero para que las tiendas se pinten encima.
    final markers = <Marker>[
      Marker(
        point: result.userPosition,
        width: 22,
        height: 22,
        child: const _UserDot(),
      ),
    ];
    for (var i = 0; i < result.stores.length; i++) {
      final store = result.stores[i];
      markers.add(
        Marker(
          point: store.point,
          width: 34,
          height: 34,
          child: _StoreMarker(
            number: i + 1,
            onTap: () => onStoreTap(store),
          ),
        ),
      );
    }

    return FlutterMap(
      // initialCameraFit solo se aplica la primera vez que se construye el
      // mapa. Con esta key, cada búsqueda nueva crea un mapa nuevo y vuelve
      // a encuadrar las tiendas.
      key: ObjectKey(result),
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: visiblePoints,
          padding: const EdgeInsets.all(40),
          maxZoom: 16,
        ),
        interactionOptions: const InteractionOptions(
          // Todo menos girar el mapa y hacer zoom (~ es no) con la rueda del ratón:
          // la rueda la necesita la página para hacer scroll.
          flags: InteractiveFlag.all &
              ~InteractiveFlag.rotate &
              ~InteractiveFlag.scrollWheelZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrlTemplate,
          // Identifica la app ante el servidor de teselas (lo exige la
          // política de uso de OpenStreetMap).
          userAgentPackageName: MapConfig.userAgentPackageName,
          maxZoom: MapConfig.maxZoom,
        ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution(
              MapConfig.attributionText, // se muestra como "© colaboradores…"
              onTap: () => launchUrl(Uri.parse(MapConfig.attributionUrl)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Círculo morado con el número de la tienda.
class _StoreMarker extends StatelessWidget {
  final int number;
  final VoidCallback onTap;

  const _StoreMarker({required this.number, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Punto azul de "estás aquí".
class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4),
        ],
      ),
    );
  }
}
