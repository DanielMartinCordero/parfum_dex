import 'package:cloud_functions/cloud_functions.dart';
import 'package:latlong2/latlong.dart';

import '../../models/nearby_store.dart';

/// Repositorio real: pide las tiendas a la Cloud Function `nearbyStores`
/// (functions/main.py).
///
/// La app no lee la colección `stores` directamente (las reglas lo impiden):
/// la función hace la búsqueda por radio y devuelve como mucho 5 tiendas.
class CloudFunctionStoresRepository {
  // Misma región en la que se despliega la función.
  final HttpsCallable _nearbyStores =
      FirebaseFunctions.instanceFor(region: 'europe-southwest1').httpsCallable(
    'nearbyStores',
    // Sin esto, la espera por defecto es de 60 s: demasiado para una
    // pantalla que muestra un spinner.
    options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
  );

  /// Devuelve como mucho 5 tiendas ordenadas por distancia y el radio (km)
  /// con el que se encontraron: 2, 10, 25 o 40.
  Future<({int radiusKm, List<NearbyStore> stores})> findNearby(LatLng position) async {
    final response = await _nearbyStores.call<Object?>({
      'lat': position.latitude,
      'lng': position.longitude,
    });

    // En Android los mapas llegan como Map<Object?, Object?>: se convierten a
    // Map<String, dynamic>, que es lo que espera NearbyStore.fromMap.
    final data = Map<String, dynamic>.from(response.data as Map);
    final rawStores = data['stores'] as List;

    final stores = <NearbyStore>[];
    for (final raw in rawStores) {
      stores.add(NearbyStore.fromMap(Map<String, dynamic>.from(raw as Map)));
    }

    return (radiusKm: (data['radiusKm'] as num).toInt(), stores: stores);
  }
}
