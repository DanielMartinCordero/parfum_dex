import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Por qué no se pudo obtener la ubicación.
enum LocationFailure {
  /// El GPS / servicio de ubicación del dispositivo está apagado.
  serviceDisabled,

  /// El usuario rechazó el permiso (se puede volver a pedir).
  denied,

  /// El usuario rechazó el permiso para siempre: solo se arregla en ajustes.
  deniedForever,

  /// Hay permiso, pero no se consiguió una posición (timeout, error...).
  unavailable,
}

class LocationException implements Exception {
  final LocationFailure failure;
  const LocationException(this.failure);

  @override
  String toString() => 'LocationException($failure)';
}

/// Envuelve `geolocator`. El permiso solo se pide cuando se llama a
/// [getCurrentPosition], es decir, cuando el usuario pulsa el botón.
class LocationService {
  const LocationService();

  /// Ubicación aproximada: para radios de varios km basta y es más rápida.
  static LocationSettings get _settings {
    if (kIsWeb) {
      // En web, requestPermission() ya obtiene una posición para que salga
      // el aviso del navegador. maximumAge deja reutilizarla (o cualquier
      // otra de los últimos 5 min) en vez de pedir otra desde cero.
      // Sin timeLimit: geolocator_web lo pasa en microsegundos en lugar de
      // milisegundos, así que 15 s se convertirían en unas 4 horas.
      return WebSettings(
        accuracy: LocationAccuracy.low,
        maximumAge: const Duration(minutes: 5),
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      );
    }
  }

  Future<LatLng> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.denied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(locationSettings: _settings);
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      // En móvil, si no llega una posición nueva a tiempo, la última conocida
      // sirve de sobra para buscar tiendas a varios km. En web no existe.
      if (!kIsWeb) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LatLng(last.latitude, last.longitude);
      }
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  /// Abre los ajustes de la app (permiso denegado para siempre). En web no
  /// hay ajustes que abrir: el permiso se cambia desde el navegador.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Abre los ajustes de ubicación del sistema (GPS apagado).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
