import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img; // prefijo: su Image choca con el widget
import 'package:image_picker/image_picker.dart';

import '../photo_service.dart';
import 'image_compression.dart';

// Android (y cualquier plataforma nativa): la foto llega entera del picker
// (12 MP o más) y se reduce en un isolate para no congelar la interfaz.

/// Ancho final de la foto, en píxeles. El alto se calcula solo.
const int _targetWidth = 400;

/// Calidad JPEG con la que se empieza, la mínima y cuánto se baja cada vez.
const int _startQuality = 70;
const int _minQuality = 30;
const int _qualityStep = 10;

Future<Uint8List> compressPhoto(XFile file) async {
  // Leer el fichero es esperar al disco, no cálculo: va en el hilo principal
  final Uint8List bytes = await file.readAsBytes();
  // Al isolate solo viajan los bytes. Si _compress lanza una PhotoException,
  // Isolate.run la vuelve a lanzar aquí, y le llega al await del panel
  return Isolate.run(() => _compress(bytes));
}

/// Corre en el otro isolate. Va fuera de compressPhoto a propósito (como en
/// ranker_native.dart): así no arrastra nada que no se pueda enviar.
Uint8List _compress(Uint8List bytes) {
  // 1. Bytes JPEG/PNG -> píxeles. Es el paso más lento (12 MP son 12 millones
  //    de píxeles), y por eso todo esto va en un isolate
  final img.Image? decoded = _decode(bytes);
  if (decoded == null) {
    // Formato que el paquete no entiende, como el HEIC de los iPhone
    throw const PhotoException(PhotoFailure.unsupportedFormat);
  }

  // 2. El móvil guarda casi todas las fotos "tumbadas" y apunta en el EXIF
  //    cuánto hay que girarlas. Esto aplica ese giro a los píxeles; sin él,
  //    al reducirla se perdería el dato y la foto saldría de lado
  final img.Image upright = img.bakeOrientation(decoded);

  // 3. Reducir a 400 px de ancho. Sin height, el alto se calcula solo para no
  //    deformarla. "average" mezcla los píxeles que se juntan: al reducir
  //    tanto (de ~4000 a 400) queda mucho más suave que el "nearest" por defecto
  final img.Image resized = img.copyResize(
    upright,
    width: _targetWidth,
    interpolation: img.Interpolation.average,
  );

  // 4. Píxeles -> JPEG. Si el Base64 no cabe en el límite, se repite con
  //    menos calidad: 70, 60, 50, 40, 30
  for (int quality = _startQuality;
      quality >= _minQuality;
      quality -= _qualityStep) {
    final Uint8List jpg = img.encodeJpg(resized, quality: quality);
    if (base64Length(jpg.length) < maxPhotoLength) return jpg;
  }

  // 5. Ni con la calidad mínima cabe (con 400 px es casi imposible)
  throw const PhotoException(PhotoFailure.tooLarge);
}

/// decodeImage devuelve null si no reconoce el formato, pero si lo reconoce
/// y el fichero está dañado puede lanzar una excepción. Las dos cosas
/// significan lo mismo para el usuario: esa imagen no se puede usar
img.Image? _decode(Uint8List bytes) {
  try {
    return img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
}
