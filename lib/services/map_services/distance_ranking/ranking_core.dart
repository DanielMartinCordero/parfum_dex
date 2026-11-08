import 'dart:math' as math;

// Cálculo puro (sin Flutter ni Firebase) de distancias y orden. Lo usan las
// dos implementaciones: la nativa lo ejecuta dentro de un isolate y la web
// en el hilo principal.
//
// Solo trabaja con números y records de números: es lo que se puede enviar
// a otro isolate sin problemas.

/// Una coordenada (latitud, longitud) en grados.
typedef GeoCoord = ({double lat, double lng});

/// Posición de un punto en la lista original y su distancia al usuario.
typedef RankedPoint = ({int index, double distanceKm});

const _earthRadiusKm = 6371.0;

/// Distancia en línea recta sobre la superficie de la Tierra (fórmula del
/// haversine), en kilómetros.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  double toRadians(double degrees) => degrees * math.pi / 180;

  final dLat = toRadians(lat2 - lat1);
  final dLng = toRadians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRadians(lat1)) *
          math.cos(toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
}

/// Cada cuántos puntos hay que avisar del progreso para dar como mucho 100
/// avisos (uno por cada 1 %). Con 5 puntos se avisa en cada uno; con 100.000,
/// cada 1.000. Avisar en cada punto saldría caro: cada aviso desde un isolate
/// es un mensaje entre hilos.
int progressStep(int total) {
  final step = total ~/ 100;
  if (step < 1) return 1;
  return step;
}

/// Calcula la distancia de cada punto a ([lat], [lng]) y los devuelve
/// ordenados de más cerca a más lejos. Llama a [onProgress] con un valor de
/// 0 a 1 como mucho 100 veces, y siempre al terminar el último punto.
List<RankedPoint> rankPointsSync(
  double lat,
  double lng,
  List<GeoCoord> points, {
  void Function(double progress)? onProgress,
}) {
  final step = progressStep(points.length);
  final ranked = <RankedPoint>[];
  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    ranked.add((index: i, distanceKm: haversineKm(lat, lng, point.lat, point.lng)));

    final done = i + 1;
    if (done % step == 0 || done == points.length) {
      onProgress?.call(done / points.length);
    }
  }
  ranked.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return ranked;
}
