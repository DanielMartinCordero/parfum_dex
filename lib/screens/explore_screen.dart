import 'package:flutter/material.dart';

import '../models/perfume.dart';
import '../services/perfumes_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PerfumesService _perfumesService = PerfumesService();
  late Future<List<Perfume>> _perfumesFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Para saber si el cursor está en la caja

  bool _isFocused = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _perfumesFuture = _perfumesService.getPerfumes();
    // Escuchamos cuándo el usuario toca dentro o fuera de la barra
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
      // Si el usuario toca fuera de la barra, quitamos el foco
      onTap: () => _searchFocusNode.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxBarWidth = constraints.maxWidth;

                return Container(
                  height: 52,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      // CAPA 1: el color que entra de derecha a izquierda
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          width: _isFocused ? maxBarWidth : 0,
                          height: 52,
                          color: Colors.deepPurple,
                        ),
                      ),

                      // CAPA 2: el TextField encima
                      Center(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            color: _isFocused ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          cursorColor: Colors.white,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase().trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar perfume, marca o nota...',
                            hintStyle: TextStyle(
                              color: _isFocused
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: _isFocused ? Colors.white : Colors.deepPurple,
                            ),
                            suffixIcon: (_isFocused || _searchQuery.isNotEmpty)
                                ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: _isFocused
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              onPressed: _clearSearch,
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Catálogo
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
                    maxCrossAxisExtent: 140, // móvil: 3 columnas; tablet/web escala solo
                    mainAxisExtent: 200,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredPerfumes.length,
                  itemBuilder: (context, index) {
                    final perfume = filteredPerfumes[index];
                    return _PerfumeCard(
                      perfume: perfume,
                      onTap: () {
                        // TODO: Navegar a los detalles
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

/// Tarjeta vertical del catálogo: imagen, marca, nombre y precio.
/// Privada por ahora; en el siguiente commit se mueve a widgets/perfume_card.dart.
class _PerfumeCard extends StatelessWidget {
  final Perfume perfume;
  final VoidCallback? onTap;

  const _PerfumeCard({required this.perfume, this.onTap});

  @override
  Widget build(BuildContext context) {
    final offer = perfume.bestOffer;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            Expanded(
              flex: 5,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: 'perfume-${perfume.brand}-${perfume.name}',
                        child: Image.network(
                          perfume.imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    if (perfume.concentration.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            perfume.concentration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Datos
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfume.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      perfume.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            offer != null
                                ? '${offer.price.toStringAsFixed(0)} €'
                                : 'Ver opciones',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: offer != null ? 14 : 11,
                              fontWeight: offer != null ? FontWeight.w800 : FontWeight.w500,
                              color: offer != null ? Colors.deepPurple : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (offer != null) //No tiene sentido mostrar una cantidad sin precio
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${perfume.nominalMl} ml',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}