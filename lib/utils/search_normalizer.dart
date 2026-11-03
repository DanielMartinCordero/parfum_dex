// Letras con tilde o especiales y su equivalente sin ellas
const Map<String, String> _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y',
  'æ': 'ae', 'œ': 'oe', 'ß': 'ss',
};

// Apóstrofos: se quitan sin dejar hueco, para que "jadore" encuentre "J'adore"
const Set<String> _apostrophes = {"'", '’', '‘', '`', '´'};

final RegExp _letterOrDigit = RegExp(r'[a-z0-9]');
final RegExp _spaces = RegExp(r'\s+');

// Prepara un texto para comparar en el buscador: minúsculas, sin tildes,
// sin apóstrofos y con el resto de símbolos convertidos en espacios.
// Ejemplos: "Lancôme" -> "lancome", "Dolce&Gabbana" -> "dolce gabbana".
String normalizeForSearch(String text) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in text.toLowerCase().runes) {
    final String char = String.fromCharCode(rune);
    if (_apostrophes.contains(char)) continue;
    final String plain = _accents[char] ?? char;
    buffer.write(_letterOrDigit.hasMatch(plain) ? plain : ' ');
  }
  return buffer.toString().replaceAll(_spaces, ' ').trim();
}
