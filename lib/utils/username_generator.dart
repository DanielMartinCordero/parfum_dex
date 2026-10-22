import 'dart:math';

/// Funciones puras para generar handles de usuario (sin tocar Firestore).
class UsernameGenerator {
  /// Longitud mínima y máxima de la parte base (sin sufijo numérico).
  static const int minLength = 3;
  static const int maxBaseLength = 20;

  // Pares carácter acentuado -> carácter plano. Ambas cadenas deben tener
  // exactamente la misma longitud: el índice i de una corresponde al de la otra.
  static const String _accented = 'áàâãäåçéèêëíìîïñóòôõöúùûüýÿ';
  static const String _plain = 'aaaaaaceeeeiiiinooooouuuuyy';

  /// Convierte "Daniel Martín" en "danielmartin".
  static String normalize(String name) {
    var result = name.toLowerCase();

    for (var i = 0; i < _accented.length; i++) {
      result = result.replaceAll(_accented[i], _plain[i]);
    }

    result = result.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (result.length > maxBaseLength) {
      result = result.substring(0, maxBaseLength);
    }

    return result.isEmpty ? 'user' : result;
  }

  /// Devuelve, en orden, los handles a probar para una base ya normalizada.
  static Iterable<String> candidates(String base, {Random? random}) sync* {
    final rng = random ?? Random();

    if (base.length >= minLength) yield base;

    for (final digits in const [4, 4, 4, 6, 6, 6, 8, 8, 8]) {
      yield '$base${_randomDigits(digits, rng)}';
    }
  }

  static String _randomDigits(int length, Random rng) {
    return List.generate(length, (_) => rng.nextInt(10)).join();
  }
}
