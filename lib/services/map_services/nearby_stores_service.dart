import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../dev/fake_stores_repository.dart';
import '../../models/nearby_store.dart';

/// Origen de las tiendas cercanas. La implementación real será la Cloud
/// Function `nearbyStores`; mientras no esté desplegada se usa
/// [FakeStoresRepository].
abstract interface class StoresRepository {
  /// Devuelve como mucho 5 tiendas ordenadas por distancia y el radio (km)
  /// con el que se encontraron: 2, 10, 25 o 40.
  Future<({int radiusKm, List<NearbyStore> stores})> findNearby(LatLng position);
}

/// Busca perfumerías cerca del usuario y guarda el último resultado en
/// memoria, compartido por todas las fichas de perfume durante la sesión:
/// abrir otro perfume no vuelve a pedir la ubicación ni a consultar nada.
/// Solo [search] (el botón de recargar) repite la búsqueda.
class NearbyStoresService {
  // Cuando la Cloud Function esté desplegada, aquí irá el repositorio real.
  static final StoresRepository _defaultRepository = FakeStoresRepository();

  // La única instancia del servicio (singleton): así todas las fichas de
  // la pantalla perfume_details comparten la misma caché.
  static final NearbyStoresService instance = NearbyStoresService._(_defaultRepository);

  /// Pasado este tiempo el resultado se descarta: el usuario puede haberse
  /// movido y las tiendas ya no serían las más cercanas.
  static const cacheTtl = Duration(minutes: 30);

  final StoresRepository _repository;

  NearbyStoresResult? _cached;

  //Constructor
  NearbyStoresService._(this._repository);

  /// Último resultado de la sesión, o null si aún no se ha buscado o si ya
  /// ha caducado.
  NearbyStoresResult? get cached {
    final result = _cached;
    if (result == null || result.age > cacheTtl) return null;
    return result;
  }

  Future<NearbyStoresResult> search(LatLng position) async {
    final response = await _repository.findNearby(position);
    final result = NearbyStoresResult(
      radiusKm: response.radiusKm,
      stores: response.stores,
      userPosition: position,
      searchedAt: Timestamp.now(),
    );
    _cached = result;
    return result;
  }
}
