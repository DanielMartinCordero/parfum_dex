

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PhotoService {

  Future<XFile?> pickImage(bool isCamera) async {
    final picker = ImagePicker();
    final XFile? image;
    if (isCamera && !kIsWeb) {
      final PermissionStatus permission = await Permission.camera.request();
      if (permission.isPermanentlyDenied) {
        throw const PhotoException(PhotoFailure.permanentlyDenied);
      }
      if (!permission.isGranted) {
        throw const PhotoException(PhotoFailure.denied);
      }
    }
    try {
      image = isCamera ? await picker.pickImage(
          source: ImageSource.camera) :
          await picker.pickImage(source: ImageSource.gallery,
            maxWidth: kIsWeb ? 400 : null,
            imageQuality: kIsWeb ? 70 : null,);
      return image;
    }
    on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw const PhotoException(PhotoFailure.denied);
      }
      rethrow;
    }
  }
}
/// Por qué no se pudo conseguir la foto.
enum PhotoFailure {
  denied,           // dijo "No permitir": se puede volver a pedir
  permanentlyDenied, // solo se arregla en ajustes
}

class PhotoException implements Exception {
  final PhotoFailure failure;
  const PhotoException(this.failure);
}