import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../photo_service.dart';
import 'image_compression.dart';

// Web: dart:isolate no existe en el navegador. Por eso la reducción la hace
// el propio picker (maxWidth: 400, imageQuality: 70 en PhotoService) y aquí
// solo se comprueba que cabe. Misma firma que la versión nativa.

Future<Uint8List> compressPhoto(XFile file) async {
  final Uint8List bytes = await file.readAsBytes();

  // El picker de web no permite bajar más la calidad después, así que si
  // no cabe (algo muy raro con 400 px) solo queda avisar
  if (base64Length(bytes.length) >= maxPhotoLength) {
    throw const PhotoException(PhotoFailure.tooLarge);
  }

  return bytes;
}
