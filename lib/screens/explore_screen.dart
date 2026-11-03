import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../services/catalog_search_service.dart';
import '../widgets/perfume_card.dart';
import '../widgets/search_bar_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final CatalogSearchService _catalogService = CatalogSearchService.instance;
  late Future<List<CatalogEntry>> _catalogFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isFocused = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // La primera vez descarga el índice (1 lectura); después ya está en memoria
    _catalogFuture = _catalogService.load();
    _searchFocusNode.addListener(() {
      setState(() {
        _isFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
    });
  }

  void _reloadCatalog() {
    setState(() {
      _catalogFuture = _catalogService.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Añadimos el AppBar
      appBar: AppBar(title: const Text("ParfumDex")),
      body: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isFocused: _isFocused,
              searchQuery: _searchQuery,
              onChanged: (value) {
                // El servicio ya normaliza (minúsculas, tildes...): aquí solo
                // quitamos los espacios de los extremos para el mensaje
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              onClear: _clearSearch,
            ),
            Expanded(
              child: FutureBuilder<List<CatalogEntry>>(
                future: _catalogFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          const Text('Error al cargar los perfumes.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _reloadCatalog,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Búsqueda en memoria: no gasta lecturas y tarda menos de
                  // un milisegundo, así que se hace en cada pulsación
                  final filteredPerfumes = _catalogService.search(_searchQuery);

                  if (filteredPerfumes.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No hay perfumes en el catálogo.'
                            : 'No se encontraron resultados para "$_searchQuery".',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 140,
                          mainAxisExtent: 200,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    // GridView.builder solo construye las tarjetas visibles,
                    // así que pasarle los 993 no cuesta nada
                    itemCount: filteredPerfumes.length,
                    itemBuilder: (context, index) {
                      return PerfumeCard(entry: filteredPerfumes[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
