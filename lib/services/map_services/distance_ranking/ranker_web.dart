import 'ranking_core.dart';

// Web: el navegador no tiene isolates de Dart (dart:isolate no existe en
// web), así que el cálculo va en el hilo principal. Para que la interfaz
// pueda repintar la barra de progreso, cada cierto número de puntos se cede
// el turno al navegador.

/// Para el registro de tiempos: en web no hay isolate.
const usesIsolate = false;

/// Cada cuántos puntos se cede el turno para que la interfaz respire.
const _yieldEvery = 50;

/// Misma firma que la versión nativa, para que quien la usa no note la
/// diferencia.
Future<List<RankedPoint>> rankPoints(
  double lat,
  double lng,
  List<GeoCoord> points,
  void Function(double progress)? onProgress,
) async {
  final step = progressStep(points.length);
  final ranked = <RankedPoint>[];
  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    ranked.add((index: i, distanceKm: haversineKm(lat, lng, point.lat, point.lng)));

    final done = i + 1;
    if (done % step == 0 || done == points.length) {
      onProgress?.call(done / points.length);
    }

    if (done % _yieldEvery == 0) {
      // Future.delayed(zero) no espera tiempo real: pone el resto del bucle
      // al final de la cola, y el navegador aprovecha para pintar.
      await Future<void>.delayed(Duration.zero);
    }
  }
  ranked.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return ranked;
}
