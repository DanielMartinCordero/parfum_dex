import '../utils/search_normalizer.dart';

/// Resumen de un perfume dentro del índice catalog/searchIndex.
/// Solo lleva lo que necesitan la tarjeta del catálogo y el buscador;
/// el perfume completo se lee de perfumes/{id} al abrir el detalle.
class CatalogEntry {
  final String id;
  final String brand;
  final String name;
  final String imageUrl;
  final String genre;
  final List<String> notes;

  // Texto ya preparado para buscar. Se calcula una sola vez al crear la
  // entrada, no en cada pulsación del teclado.
  final String searchName; // "le male"
  final String searchTitle; // "jean paul gaultier le male"
  final List<String> searchWords; // ["jean", "paul", "gaultier", "le", "male"]
  final Set<String> searchNoteWords; // {"lavender", "mint", "tonka", "bean", ...}

  const CatalogEntry._({
    required this.id,
    required this.brand,
    required this.name,
    required this.imageUrl,
    required this.genre,
    required this.notes,
    required this.searchName,
    required this.searchTitle,
    required this.searchWords,
    required this.searchNoteWords,
  });

  factory CatalogEntry.fromMap(Map<String, dynamic> map) {
    final String brand = map['brand'] as String? ?? '';
    final String name = map['name'] as String? ?? '';
    final List<String> notes = map['notes'] is List
        ? (map['notes'] as List).whereType<String>().toList()
        : const [];
    final String searchTitle = normalizeForSearch('$brand $name');

    return CatalogEntry._(
      id: map['id'] as String? ?? '',
      brand: brand,
      name: name,
      imageUrl: map['imageUrl'] as String? ?? '',
      genre: map['genre'] as String? ?? '',
      notes: notes,
      searchName: normalizeForSearch(name),
      searchTitle: searchTitle,
      searchWords: searchTitle.split(' '),
      searchNoteWords: normalizeForSearch(notes.join(' '))
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toSet(),
    );
  }
}
