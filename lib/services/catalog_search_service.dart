import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/catalog_entry.dart';
import '../utils/search_normalizer.dart';

// Descarga el índice del catálogo (catalog/searchIndex) y busca en él en local.
// Firestore no sabe buscar texto dentro de un campo, así que traemos un único
// documento con todos los perfumes resumidos: 1 lectura por sesión.
class CatalogSearchService {
  // Singleton: una sola instancia para toda la app, así el índice se descarga
  // una vez y se queda en memoria aunque cambiemos de pantalla.
  CatalogSearchService._();
  static final CatalogSearchService instance = CatalogSearchService._();

  Future<List<CatalogEntry>>? _loading;
  List<CatalogEntry> _entries = const [];

  // Descarga el índice la primera vez y devuelve siempre la misma lista,
  // barajada una sola vez por sesión.
  Future<List<CatalogEntry>> load() {
    // Si ya se ha descargado (o se está descargando), reutilizamos ese Future
    return _loading ??= _download();
  }

  Future<List<CatalogEntry>> _download() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('catalog')
          .doc('searchIndex')
          .get();
      final data = snapshot.data();
      if (data == null || data['items'] is! List) {
        throw Exception('El índice del catálogo no existe o está vacío.');
      }

      final List<CatalogEntry> entries = [];
      for (final item in data['items'] as List) {
        // Solo nos valen los elementos que son mapas
        if (item is Map<String, dynamic>) {
          // Transformamos el mapa a nuestro tipo
          final CatalogEntry entry = CatalogEntry.fromMap(item);
          // Sin id no se podría abrir el detalle
          if (entry.id.isNotEmpty) {
            entries.add(entry);
          }
        }
      }
      // Barajamos una sola vez por sesión
      entries.shuffle();
      debugPrint('Índice del catálogo descargado: ${entries.length} perfumes');
      _entries = entries;
      return entries;
    } catch (e) {
      debugPrint('Error al descargar el índice del catálogo: $e');
      // Olvidamos el Future fallido para que "Reintentar" vuelva a descargar
      _loading = null;
      rethrow;
    }
  }

  // Busca en el índice ya descargado. Sin texto, devuelve el catálogo barajado.
  List<CatalogEntry> search(String query) => searchCatalog(_entries, query);
}

/// Filtra y ordena las entradas según lo escrito. Está fuera de la clase para
/// poder probarla sin Firestore.
///
/// Cada palabra escrita tiene que aparecer en la marca, el nombre o las notas.
/// Orden de relevancia:
///   0. el nombre o "marca nombre" empiezan por lo escrito (sauvage, je)
///   1. cada palabra es el principio de una palabra de la marca o el nombre (le ma)
///   2. cada palabra está dentro de la marca o el nombre (auva -> Sauvage)
///   3. alguna palabra solo aparece en las notas, al principio de una palabra
///      (vanilla, tonka). Así "eros" no encuentra la nota "Tuberose".
/// A igual relevancia, orden alfabético.
List<CatalogEntry> searchCatalog(List<CatalogEntry> entries, String query) {
  final String text = normalizeForSearch(query);
  if (text.isEmpty) return entries;
  final List<String> words = text.split(' ');

  final List<({CatalogEntry entry, int rank})> matches = [];
  for (final CatalogEntry entry in entries) {
    final int? rank = _rank(entry, text, words);
    if (rank != null) { //Descartamos los que no devuelven ninguna coincidencia
      matches.add((entry: entry, rank: rank));
    }
  }

  matches.sort((a, b) {
    final int byRank = a.rank.compareTo(b.rank);
    return byRank != 0
        ? byRank
        : a.entry.searchTitle.compareTo(b.entry.searchTitle);
  });
  return [for (final match in matches) match.entry];
}

// Devuelve la relevancia de una entrada (0 es la mejor) o null si no encaja
int? _rank(CatalogEntry entry, String text, List<String> words) {
  if (entry.searchName.startsWith(text) || entry.searchTitle.startsWith(text)) {
    return 0;
  }
  if (words.every((word) => entry.searchWords.any((w) => w.startsWith(word)))) {
    return 1;
  }
  if (words.every(entry.searchTitle.contains)) {
    return 2;
  }
  if (words.every((word) =>
      entry.searchTitle.contains(word) ||
      entry.searchNoteWords.any((note) => note.startsWith(word)))) {
    return 3;
  }
  return null;
}
