

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../preferences_service.dart';

class PhotoService {

  Future<XFile?> pickImage(bool isCamera, String itemId) async {
    final picker = ImagePicker();
    if (isCamera && !kIsWeb) {
      final PermissionStatus permission = await Permission.camera.request();
      if (permission.isPermanentlyDenied) {
        throw const PhotoException(PhotoFailure.permanentlyDenied);
      }
      if (!permission.isGranted) {
        throw const PhotoException(PhotoFailure.denied);
      }
    }

    // Se apunta de qué frasco es la foto por si Android cierra la app con la
    // cámara abierta (ver recoverLostPhoto). Va después del permiso: si se
    // deniega, el throw de arriba saldría sin pasar por el finally y el id
    // se quedaría guardado. El await asegura que está escrito antes de abrirla
    await PreferencesService.setPendingPhotoItemId(itemId);
    try {
      // Una sola llamada para cámara y galería. En web el picker ya reduce la
      // foto (allí no hay isolate); en Android llega entera y la comprime
      // image_compression en un isolate
      return await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: kIsWeb ? 400 : null,
        imageQuality: kIsWeb ? 70 : null,
      );
    }
    on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw const PhotoException(PhotoFailure.denied);
      }
      rethrow;
    }
    finally {
      // Si llegamos aquí la app no murió (hubo foto, cancelación o error):
      // ya no hay nada que recuperar
      await PreferencesService.clearPendingPhotoItemId();
    }
  }

  /// Foto que se quedó a medias porque Android cerró la app mientras la
  /// cámara estaba abierta. Devuelve la foto y el frasco al que pertenecía,
  /// o null si no hay nada que recuperar (lo normal). Solo existe en Android.
  /// Solo recupera: comprimir y guardar lo hace quien la llama, como en el panel
  Future<({String itemId, XFile file})?> recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

    // La foto: image_picker la guardó al morir la app
    final LostDataResponse response = await ImagePicker().retrieveLostData();

    // El frasco: lo apuntó pickImage antes de abrir la cámara. Se lee y se
    // borra enseguida, haya foto o no, para no recuperarla dos veces
    final String? itemId = PreferencesService.pendingPhotoItemId;
    await PreferencesService.clearPendingPhotoItemId();

    // Copia local: así Dart sabe que tras comprobarla ya no es null
    final XFile? file = response.file;
    if (response.isEmpty || file == null || itemId == null) return null;

    return (itemId: itemId, file: file);
  }
}
/// Por qué no se pudo conseguir la foto.
enum PhotoFailure {
  denied,           // dijo "No permitir": se puede volver a pedir
  permanentlyDenied, // solo se arregla en ajustes
  unsupportedFormat, // decodeImage no la entiende (por ejemplo HEIC)
  tooLarge,          // ni con la calidad mínima baja de 300 000 caracteres
}

class PhotoException implements Exception {
  final PhotoFailure failure;
  const PhotoException(this.failure);
}