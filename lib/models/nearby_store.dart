import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Una perfumería devuelta por la búsqueda de "Perfumerías cerca de ti".
///
/// Refleja el contrato de la Cloud Function `nearbyStores`:
///   petición  {lat, lng}
///   respuesta {radiusKm, stores: [NearbyStore...]}
class NearbyStore {
  final String id;
  final String chain;
  final String? address;
  final String? postalCode;
  final String? city;
  // Mismo tipo que el campo `location` del documento en Firestore.
  final GeoPoint location;
  final double distanceKm;
  final String? phone;
  // Horario semanal: 7 listas (lunes a domingo) con tramos "HH:MM-HH:MM".
  // Una lista vacía significa cerrado ese día. `null` si no hay horario.
  final List<List<String>>? weeklyHours;

  const NearbyStore({
    required this.id,
    required this.chain,
    required this.location,
    required this.distanceKm,
    this.address,
    this.postalCode,
    this.city,
    this.phone,
    this.weeklyHours,
  });

  // flutter_map trabaja con LatLng, así que lo convertimos para el marcador.
  LatLng get point => LatLng(location.latitude, location.longitude);

  /// "28013 Madrid", "Madrid" o null.
  String? get locality {
    final parts = [postalCode, city].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  factory NearbyStore.fromMap(Map<String, dynamic> map) {
    final hours = map['weeklyHours'] as List?;
    return NearbyStore(
      id: map['id'] as String,
      chain: map['chain'] as String? ?? 'Perfumería',
      address: map['address'] as String?,
      postalCode: map['postalCode'] as String?,
      city: map['city'] as String?,
      // La respuesta de la función es JSON y no puede llevar un GeoPoint,
      // así que viaja como lat/lng y aquí lo reconstruimos.
      location: GeoPoint(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      ),
      distanceKm: (map['distanceKm'] as num).toDouble(),
      phone: map['phone'] as String?,
      weeklyHours: hours
          ?.map((day) => (day as List).map((t) => t as String).toList())
          .toList(),
    );
  }
}

/// Resultado de una búsqueda: las tiendas (como mucho 5, ordenadas por
/// distancia), el radio con el que se encontraron y dónde estaba el usuario.
///
/// La posición del usuario solo vive en memoria para centrar el mapa;
/// no se persiste en ningún sitio.
class NearbyStoresResult {
  final int radiusKm;
  final List<NearbyStore> stores;
  final LatLng userPosition;

  // Cuándo se hizo la búsqueda: para el "Actualizado hace 5 min" y para que
  // la caché caduque.
  final Timestamp searchedAt;

  const NearbyStoresResult({
    required this.radiusKm,
    required this.stores,
    required this.userPosition,
    required this.searchedAt,
  });

  /// Tiempo transcurrido desde la búsqueda.
  Duration get age => DateTime.now().difference(searchedAt.toDate());
}
