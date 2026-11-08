import 'dart:async' show TimeoutException;

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

  /// Hay permiso, pero la posición no llegó dentro del tiempo límite.
  timeout,

  /// Hay permiso, pero no se consiguió una posición (error del sistema).
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

  /// Cuánto se espera a la posición antes de rendirse. Se aplica con
  /// Future.timeout (Dart) y no con el timeLimit de geolocator, porque
  /// geolocator_web lo pasa en microsegundos en lugar de milisegundos y en
  /// web 15 s se convertirían en unas 4 horas. Así funciona igual en todas
  /// las plataformas.
  static const _timeout = Duration(seconds: 15);

  /// Precisión "media": en Android es PRIORITY_BALANCED_POWER_ACCURACY del
  /// proveedor combinado (~100 m, con Wi-Fi y antenas, sin encender el GPS).
  /// Basta para buscar tiendas a partir de 2 km y gasta poca batería.
  /// `low` sería PRIORITY_LOW_POWER (~10 km, nivel ciudad): demasiado
  /// impreciso para el primer radio. En web, medium deja
  /// enableHighAccuracy a false (ubicación por red).
  static const _accuracy = LocationAccuracy.medium;

  static LocationSettings get _settings {
    if (kIsWeb) {
      // En web, requestPermission() ya obtiene una posición para que salga
      // el aviso del navegador. maximumAge deja reutilizarla (o cualquier
      // otra de los últimos 5 min) en vez de pedir otra desde cero.
      return WebSettings(
        accuracy: _accuracy,
        maximumAge: const Duration(minutes: 5),
      );
    } else {
      return const LocationSettings(accuracy: _accuracy);
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
      final position = await Geolocator.getCurrentPosition(locationSettings: _settings)
          .timeout(_timeout);
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      // Se acabó el tiempo. En móvil, la última posición conocida sirve de
      // sobra para buscar tiendas a varios km.
      final last = await _lastKnownPosition();
      if (last != null) return last;
      throw const LocationException(LocationFailure.timeout);
    } catch (_) {
      // Cualquier otro error del sistema: mismo recurso.
      final last = await _lastKnownPosition();
      if (last != null) return last;
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  /// Última posición que guardó el sistema, o null si no hay ninguna.
  /// En web no existe ese concepto.
  Future<LatLng?> _lastKnownPosition() async {
    if (kIsWeb) return null;
    final last = await Geolocator.getLastKnownPosition();
    if (last == null) return null;
    return LatLng(last.latitude, last.longitude);
  }

  /// Abre los ajustes de la app (permiso denegado para siempre). En web no
  /// hay ajustes que abrir: el permiso se cambia desde el navegador.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Abre los ajustes de ubicación del sistema (GPS apagado).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
