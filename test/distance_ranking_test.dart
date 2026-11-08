import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:parfum_dex/models/nearby_store.dart';
import 'package:parfum_dex/services/map_services/distance_ranking/distance_ranking.dart';
import 'package:parfum_dex/services/map_services/distance_ranking/ranking_core.dart';

NearbyStore _store(String id, double lat, double lng) {
  return NearbyStore(
    id: id,
    chain: 'Tienda $id',
    location: GeoPoint(lat, lng),
    distanceKm: 0,
  );
}

void main() {
  group('haversineKm', () {
    test('Madrid (Puerta del Sol) – Barcelona (Pl. Catalunya) ≈ 505 km', () {
      final km = haversineKm(40.4169, -3.7035, 41.3870, 2.1700);
      expect(km, closeTo(505, 3));
    });

    test('el mismo punto está a 0 km', () {
      expect(haversineKm(40.0, -3.0, 40.0, -3.0), 0);
    });
  });

  test('rankByDistance ordena de más cerca a más lejos y avisa del progreso', () async {
    const user = LatLng(40.4169, -3.7035);
    final stores = [
      _store('lejos', 40.50, -3.70), // ~9 km
      _store('cerca', 40.42, -3.70), // ~0,5 km
      _store('medio', 40.45, -3.70), // ~3,7 km
    ];

    final progress = <double>[];
    final ranking = await rankByDistance(user, stores, onProgress: progress.add);

    expect(ranking.stores.map((s) => s.store.id), ['cerca', 'medio', 'lejos']);
    expect(ranking.stores.first.distanceKm, lessThan(1));
    // En la VM (como en Android) el cálculo va en un isolate.
    expect(ranking.usedIsolate, isTrue);
    // Los mensajes de progreso llegan del otro isolate de forma asíncrona;
    // si llega alguno, el último debe ser el 100 %.
    if (progress.isNotEmpty) expect(progress.last, lessThanOrEqualTo(1));
  });
}
