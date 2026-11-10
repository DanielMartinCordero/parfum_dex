import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../models/nearby_store.dart';
import 'cloud_function_stores_repository.dart';

/// Busca perfumerías cerca del usuario y guarda el último resultado en
/// memoria, compartido por todas las fichas de perfume durante la sesión:
/// abrir otro perfume no vuelve a pedir la ubicación ni a consultar nada.
/// Solo [search] (el botón de recargar) repite la búsqueda.
class NearbyStoresService {
  // La única instancia del servicio (singleton): así todas las fichas de
  // la pantalla perfume_details comparten la misma caché.
  static final NearbyStoresService instance = NearbyStoresService._();

  /// Pasado este tiempo el resultado se descarta: el usuario puede haberse
  /// movido y las tiendas ya no serían las más cercanas.
  static const cacheTtl = Duration(minutes: 30);

  final CloudFunctionStoresRepository _repository = CloudFunctionStoresRepository();

  NearbyStoresResult? _cached;

  //Constructor
  NearbyStoresService._();

  /// Último resultado de la sesión, o null si aún no se ha buscado o si ya
  /// ha caducado.
  NearbyStoresResult? get cached {
    final result = _cached;
    if (result == null || result.age > cacheTtl) return null;
    return result;
  }

  /// Olvida el resultado de la sesión (y con él la posición del usuario que
  /// guardaba). La próxima ficha de perfume volverá a mostrar el botón.
  void clear() {
    _cached = null;
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
