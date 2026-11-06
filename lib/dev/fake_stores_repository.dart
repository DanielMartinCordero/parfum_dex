import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/nearby_store.dart';
import '../services/map_services/nearby_stores_service.dart';
import 'fake_stores_data.dart';

/// Casos que se pueden simular.
enum FakeScenario {
  normal, // 5 tiendas en 10 km
  few, // 3 tiendas en 40 km
  none, // ninguna tienda
  error, // fallo de red
}

/// Cambia esta línea para probar otro caso.
const fakeScenario = FakeScenario.normal;

/// Genera tiendas de ejemplo alrededor de la posición real del usuario para
/// poder probar la interfaz sin la Cloud Function. Aplica el mismo escalado
/// de radios que hará la función.
class FakeStoresRepository implements StoresRepository {
  static const _radiiKm = [2, 10, 25, 40];
  static const _maxResults = 5;

  @override
  Future<({int radiusKm, List<NearbyStore> stores})> findNearby(LatLng position) async {
    // Simula el tiempo de respuesta de la red.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (fakeScenario == FakeScenario.error) {
      throw Exception('Fallo simulado de red');
    }

    final distances = _distancesFor(fakeScenario);
    final random = math.Random(7);
    final candidates = <NearbyStore>[];
    for (var i = 0; i < distances.length; i++) {
      final bearing = random.nextDouble() * 2 * math.pi;
      candidates.add(_sample(i, position, distances[i], bearing));
    }

    // Escalado de radios: el primero que reúna 5 tiendas gana; si ninguno
    // llega, se devuelve lo que haya en el último (40 km), aunque sea nada.
    for (final radius in _radiiKm) {
      final inside = candidates.where((s) => s.distanceKm <= radius).toList();
      if (inside.length >= _maxResults || radius == _radiiKm.last) {
        return (radiusKm: radius, stores: inside.take(_maxResults).toList());
      }
    }
    throw StateError('unreachable');
  }

  List<double> _distancesFor(FakeScenario scenario) {
    switch (scenario) {
      case FakeScenario.normal:
        return normalDistancesKm;
      case FakeScenario.few:
        return fewDistancesKm;
      case FakeScenario.none:
      case FakeScenario.error:
        return [];
    }
  }

  /// Crea la tienda de ejemplo nº [i] a [distanceKm] del usuario, en la
  /// dirección [bearing] (en radianes).
  NearbyStore _sample(int i, LatLng from, double distanceKm, double bearing) {
    final template = fakeStoreTemplates[i % fakeStoreTemplates.length];
    // 1º de latitud ≈ 111,32 km; 1º de longitud se encoge con el coseno de
    // la latitud (los meridianos se juntan hacia los polos).
    final dLat = distanceKm * math.cos(bearing) / 111.32;
    final dLng = distanceKm * math.sin(bearing) /
        (111.32 * math.cos(from.latitude * math.pi / 180));
    return NearbyStore(
      id: 'fake-$i',
      chain: template.chain,
      address: template.address,
      postalCode: '28013',
      city: 'Ciudad de ejemplo',
      location: GeoPoint(from.latitude + dLat, from.longitude + dLng),
      distanceKm: distanceKm,
      phone: template.phone,
      weeklyHours: template.hours,
    );
  }
}
