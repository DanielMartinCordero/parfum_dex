import 'package:latlong2/latlong.dart';

import '../../../models/nearby_store.dart';
import 'ranking_core.dart';
// Import condicional: en web se carga ranker_web.dart y en el resto
// ranker_native.dart. Los dos exponen lo mismo (rankPoints y usesIsolate),
// así que este fichero no necesita saber en qué plataforma está.
import 'ranker_native.dart' if (dart.library.js_interop) 'ranker_web.dart'
    as platform;

/// Una tienda con su distancia al usuario.
typedef RankedStore = ({NearbyStore store, double distanceKm});

/// Resultado de ordenar: las tiendas y cuánto se tardó.
class DistanceRanking {
  final List<RankedStore> stores;
  final Duration elapsed;
  final bool usedIsolate;

  const DistanceRanking({
    required this.stores,
    required this.elapsed,
    required this.usedIsolate,
  });
}

/// Calcula la distancia de cada tienda a [from] y las ordena de más cerca a
/// más lejos. En Android lo hace en un isolate; en web, en el hilo principal.
/// [onProgress] recibe valores de 0 a 1 mientras tanto.
Future<DistanceRanking> rankByDistance(
  LatLng from,
  List<NearbyStore> stores, {
  void Function(double progress)? onProgress,
}) async {
  // Al isolate solo viajan números: las coordenadas de cada tienda.
  final points = <GeoCoord>[];
  for (final store in stores) {
    points.add((lat: store.location.latitude, lng: store.location.longitude));
  }

  final stopwatch = Stopwatch()..start();
  final rankedPoints = await platform.rankPoints(
    from.latitude,
    from.longitude,
    points,
    onProgress,
  );
  stopwatch.stop();

  // De vuelta, cada índice se convierte otra vez en su tienda.
  final ranked = <RankedStore>[];
  for (final point in rankedPoints) {
    ranked.add((store: stores[point.index], distanceKm: point.distanceKm));
  }

  return DistanceRanking(
    stores: ranked,
    elapsed: stopwatch.elapsed,
    usedIsolate: platform.usesIsolate,
  );
}
