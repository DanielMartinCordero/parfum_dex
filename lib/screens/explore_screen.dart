import 'package:flutter/material.dart';

import '../models/perfume.dart';
import '../services/perfumes_service.dart';
import '../widgets/perfume_card.dart';
import '../widgets/search_bar_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PerfumesService _perfumesService = PerfumesService();
  late Future<List<Perfume>> _perfumesFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isFocused = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _perfumesFuture = _perfumesService.getPerfumes();
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

  void _reloadPerfumes() {
    setState(() {
      _perfumesFuture = _perfumesService.getPerfumes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              setState(() {
                _searchQuery = value.toLowerCase().trim();
              });
            },
            onClear: _clearSearch,
          ),
          Expanded(
            child: FutureBuilder<List<Perfume>>(
              future: _perfumesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 12),
                        const Text('Error al cargar los perfumes.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _reloadPerfumes,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final allPerfumes = snapshot.data ?? [];
                final filteredPerfumes = _searchQuery.isEmpty
                    ? allPerfumes
                    : allPerfumes.where((perfume) {
                        final matchesName =
                            perfume.name.toLowerCase().contains(_searchQuery);
                        final matchesBrand =
                            perfume.brand.toLowerCase().contains(_searchQuery);
                        final matchesNotes = perfume.notes.values.any((list) =>
                            list.any((note) =>
                                note.toLowerCase().contains(_searchQuery)));
                        return matchesName || matchesBrand || matchesNotes;
                      }).toList();

                if (filteredPerfumes.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No hay perfumes en el catálogo.'
                          : 'No se encontraron resultados para "$_searchQuery".',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140, 
                    mainAxisExtent: 200,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredPerfumes.length,
                  itemBuilder: (context, index) {
                    final perfume = filteredPerfumes[index];
                    return PerfumeCard(
                      perfume: perfume,
                      onTap: () {
                        // Pendiente por implementar pantalla de detalles
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}