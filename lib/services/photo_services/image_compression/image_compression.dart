// Comprime la foto del frasco antes de guardarla en Firestore.
//
// Export condicional, igual que en distance_ranking: en web se usa
// compressor_web.dart y en el resto compressor_native.dart. Los dos exponen
// la misma función, compressPhoto(XFile file), así que quien importa este
// fichero no necesita saber en qué plataforma está.
export 'compressor_native.dart' if (dart.library.js_interop) 'compressor_web.dart';

/// Máximo de caracteres del texto Base64 (igual que en firestore.rules).
/// El documento admite 1 MB, pero así queda sitio de sobra para el resto.
const int maxPhotoLength = 300000;

/// Cuántos caracteres ocupará [byteCount] bytes en Base64, sin codificarlo:
/// cada 3 bytes se convierten en 4 caracteres (redondeando hacia arriba).
int base64Length(int byteCount) => ((byteCount + 2) ~/ 3) * 4;
