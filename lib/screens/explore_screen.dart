import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../services/catalog_search_service.dart';
import '../widgets/perfume_card.dart';
import '../widgets/search_bar_widget.dart';

// SOLUCIÓN PROVISIONAL: Hasta la aplicación de una interfaz responsive,
// configuramos el catálogo para evitar lag maisvo al cargar cientos de perfumes a la vez

// A partir de este ancho (PC, tablets grandes en horizontal) se usa el diseño
// de escritorio: panel a la izquierda y tarjetas grandes
const double _wideBreakpoint = 900;

// Ancho del panel izquierdo, reservado para los filtros (notas, género...)
const double _sidePanelWidth = 260;

// Máximo de columnas en PC. Con 6 columnas se ven unas 12-18 tarjetas a la vez
const int _maxColumns = 6;

// Tamaño máximo de una tarjeta en PC (ancho x alto). Si sobra sitio, la
// cuadrícula se centra y quedan franjas vacías a los lados
const double _maxCardWidth = 220;
const double _cardAspectRatio = 220 / 320;

// Separación entre tarjetas y margen mínimo a cada lado de la cuadrícula en PC
const double _gridSpacing = 16;
const double _minSidePadding = 24;

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
        // Solución provisional:
        // LayoutBuilder nos dice cuánto ancho tenemos para decidir el diseño
        //Si no, en pantallas largas se generan muchos perfumes causando lag
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= _wideBreakpoint;

            // Móvil: solo el buscador y la cuadrícula, como hasta ahora
            if (!isWide) {
              return _buildCatalog(isWide: false, columns: 0, sidePadding: 0);
            }

            // 1. Cuántas tarjetas de _maxCardWidth caben a lo ancho (mínimo 3,
            //    máximo _maxColumns)
            final double catalogWidth = constraints.maxWidth - _sidePanelWidth;
            final int columns = ((catalogWidth - 2 * _minSidePadding + _gridSpacing) /
                    (_maxCardWidth + _gridSpacing))
                .floor()
                .clamp(3, _maxColumns);

            // 2. Lo que ocupan esas columnas con su tamaño máximo; el resto
            //    se reparte a partes iguales a los lados para centrarlas
            final double gridWidth =
                columns * _maxCardWidth + (columns - 1) * _gridSpacing;
            final double sidePadding =
                math.max(_minSidePadding, (catalogWidth - gridWidth) / 2);

            // PC: panel de filtros a la izquierda y el catálogo a la derecha
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  width: _sidePanelWidth,
                  child: _FiltersPanel(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _buildCatalog(
                    isWide: true,
                    columns: columns,
                    sidePadding: sidePadding,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Buscador + cuadrícula de perfumes. En PC las tarjetas son más grandes
  // y hay un número fijo de columnas, centradas con "sidePadding" a cada lado
  // (en móvil no se usan ninguno de los dos)
  Widget _buildCatalog({
    required bool isWide,
    required int columns,
    required double sidePadding,
  }) {
    return Column(
      children: [
        // En PC el buscador se alinea con la cuadrícula. El buscador ya trae
        // 16 de margen propio, por eso restamos 16
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? sidePadding - 16 : 0,
          ),
          child: SearchBarWidget(
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
                // El margen lateral va dentro del GridView (y no fuera) para
                // que la rueda del ratón también haga scroll sobre las franjas
                padding: isWide
                    ? EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 24)
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                gridDelegate: isWide
                    // PC: columnas fijas y tarjetas con la misma proporción
                    // (220 de ancho por 320 de alto)
                    ? SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: _cardAspectRatio,
                        crossAxisSpacing: _gridSpacing,
                        mainAxisSpacing: _gridSpacing,
                      )
                    // Móvil: maxCrossAxisExtent es el ancho MÁXIMO de cada
                    // tarjeta; Flutter mete tantas columnas como quepan
                    : const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 140,
                        mainAxisExtent: 200,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                // GridView.builder solo construye las tarjetas visibles,
                // así que pasarle los 993 no cuesta nada
                itemCount: filteredPerfumes.length,
                itemBuilder: (context, index) {
                  return PerfumeCard(
                    entry: filteredPerfumes[index],
                    large: isWide,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Hueco reservado para los filtros (notas, género, temporada...).
// De momento solo indica lo que vendrá.
class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente: notas, género y temporada.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
