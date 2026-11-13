import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/catalog_entry.dart';
import '../models/perfume.dart';
import '../services/catalog_search_service.dart';
import '../services/perfumes_service.dart';
import '../widgets/catalog_filters.dart';
import '../widgets/perfume_card.dart';
import '../widgets/search_bar_widget.dart';

// SOLUCIÓN PROVISIONAL: Hasta la aplicación de una interfaz responsive,
// configuramos el catálogo para evitar lag maisvo al cargar cientos de perfumes a la vez

// A partir de este ancho (PC, tablets grandes en horizontal) se usa el diseño
// de escritorio: panel a la izquierda y tarjetas grandes
const double _wideBreakpoint = 900;

// Ancho del panel izquierdo de los filtros
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
  final PerfumesService _perfumesService = PerfumesService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isFocused = false;
  String _searchQuery = '';

  // --- Búsqueda: índice catalog/searchIndex ---
  // Solo se descarga al escribir la primera letra. Si nunca se busca,
  // no se gasta esa lectura
  Future<List<CatalogEntry>>? _catalogFuture;

  // --- Lista sin búsqueda: perfumes paginados por nombre ---
  final List<CatalogEntry> _pageEntries = [];
  // Último documento recibido: el cursor para pedir la página siguiente
  DocumentSnapshot<Perfume>? _lastDoc;
  bool _hasMore = true; // false cuando una página llega incompleta
  bool _isLoadingPage = false;
  bool _pageFailed = false;

  // --- Filtros de la lista (null = sin filtrar) ---
  String? _genre;
  String? _season;
  // Sube cada vez que cambian los filtros. Si llega una página pedida con
  // los filtros anteriores, su número ya no coincide y se descarta
  int _queryVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadNextPage(); // primera página
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

  // Pide la página siguiente a la última que tenemos. Con _lastDoc a null
  // (al empezar) pide la primera
  Future<void> _loadNextPage() async {
    // Evita pedir dos veces la misma página si se pulsa rápido
    if (_isLoadingPage || !_hasMore) return;
    setState(() {
      _isLoadingPage = true;
      _pageFailed = false;
    });

    // Apuntamos para qué filtros es esta petición
    final int version = _queryVersion;
    try {
      final page = await _perfumesService.getPerfumesPage(
        startAfter: _lastDoc,
        genre: _genre,
        season: _season,
      );
      // Si mientras esperábamos cambiaron los filtros, esta página ya no
      // pinta nada: la ignoramos
      if (!mounted || version != _queryVersion) return;
      setState(() {
        _pageEntries.addAll(page.perfumes.map(CatalogEntry.fromPerfume));
        _lastDoc = page.lastDoc ?? _lastDoc;
        // Si la página no llega llena, ya no quedan más perfumes
        _hasMore = page.perfumes.length == PerfumesService.pageSize;
        _isLoadingPage = false;
      });
    } catch (e) {
      if (!mounted || version != _queryVersion) return;
      // Conservamos lo ya cargado; el pie de la lista ofrece "Reintentar"
      setState(() {
        _isLoadingPage = false;
        _pageFailed = true;
      });
    }
  }

  // Cambiar un filtro es otra consulta: se tira lo cargado y se empieza
  // desde la primera página, con el cursor a null
  void _changeFilters({required String? genre, required String? season}) {
    if (genre == _genre && season == _season) return;
    setState(() {
      _genre = genre;
      _season = season;
      _queryVersion++; // invalida la página que pudiera estar en camino
      _pageEntries.clear();
      _lastDoc = null;
      _hasMore = true;
      _isLoadingPage = false;
      _pageFailed = false;
    });
    _loadNextPage();
  }

  // Los chips del catálogo, listos para el panel (PC) o para debajo del
  // buscador (móvil). Pulsar el chip marcado lo desmarca (null = todos)
  Widget _buildFilters({required bool vertical}) {
    return CatalogFilters(
      genre: _genre,
      season: _season,
      vertical: vertical,
      // La búsqueda va sobre el índice, que no sabe de temporadas
      enabled: _searchQuery.isEmpty,
      onGenreChanged: (genre) => _changeFilters(genre: genre, season: _season),
      onSeasonChanged: (season) => _changeFilters(genre: _genre, season: season),
    );
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
      appBar: AppBar(title: const Text("PerfumeDex")),
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
                SizedBox(
                  width: _sidePanelWidth,
                  child: CatalogFiltersPanel(
                    child: _buildFilters(vertical: true),
                  ),
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
                // Primera letra escrita: descargamos el índice (1 lectura).
                // ??= hace que solo se pida una vez
                if (_searchQuery.isNotEmpty) {
                  _catalogFuture ??= _catalogService.load();
                }
              });
            },
            onClear: _clearSearch,
          ),
        ),
        // Móvil: los chips debajo del buscador (en PC van en el panel).
        // Mientras se busca se ocultan, porque no se aplican a la búsqueda
        if (!isWide && _searchQuery.isEmpty) _buildFilters(vertical: false),
        Expanded(
          // Sin texto: lista paginada. Con texto: búsqueda en el índice
          child: _searchQuery.isEmpty
              ? _buildPagedList(isWide, columns, sidePadding)
              : _buildSearchResults(isWide, columns, sidePadding),
        ),
      ],
    );
  }

  // Catálogo completo por orden alfabético, de PerfumesService.pageSize en
  // PerfumesService.pageSize, con un botón "Cargar más" al final
  Widget _buildPagedList(bool isWide, int columns, double sidePadding) {
    // Todavía no hay ninguna página
    if (_pageEntries.isEmpty) {
      if (_pageFailed) return _buildError(_loadNextPage);
      if (_isLoadingPage) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildMessage(
        _genre != null || _season != null
            ? 'No hay perfumes con estos filtros.'
            : 'No hay perfumes en el catálogo.',
      );
    }

    // Pie de la lista: según el estado, cargando, error o "Cargar más"
    final Widget footer;
    if (_isLoadingPage) {
      footer = const Center(child: CircularProgressIndicator());
    } else if (_pageFailed) {
      footer = Column(
        children: [
          const Text('No se pudieron cargar más perfumes.'),
          TextButton(
            onPressed: _loadNextPage,
            child: const Text('Reintentar'),
          ),
        ],
      );
    } else if (_hasMore) {
      footer = Center(
        child: OutlinedButton.icon(
          onPressed: _loadNextPage,
          icon: const Icon(Icons.expand_more),
          label: const Text('Cargar más'),
        ),
      );
    } else {
      footer = Center(
        child: Text(
          'Has llegado al final del catálogo.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return _buildGrid(
      _pageEntries,
      isWide,
      columns,
      sidePadding,
      footer: footer,
    );
  }

  // Resultados de la búsqueda sobre el índice ya descargado
  Widget _buildSearchResults(bool isWide, int columns, double sidePadding) {
    return FutureBuilder<List<CatalogEntry>>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildError(_reloadCatalog);
        }

        // Búsqueda en memoria: no gasta lecturas y tarda menos de
        // un milisegundo, así que se hace en cada pulsación
        final filteredPerfumes = _catalogService.search(_searchQuery);

        if (filteredPerfumes.isEmpty) {
          return _buildMessage(
            'No se encontraron resultados para "$_searchQuery".',
          );
        }
        return _buildGrid(filteredPerfumes, isWide, columns, sidePadding);
      },
    );
  }

  // Cuadrícula de tarjetas, con un pie opcional debajo (el botón
  // "Cargar más"). CustomScrollView permite poner la cuadrícula y el pie
  // dentro del mismo scroll
  Widget _buildGrid(
    List<CatalogEntry> entries,
    bool isWide,
    int columns,
    double sidePadding, {
    Widget? footer,
  }) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          // El margen lateral va dentro del scroll (y no fuera) para
          // que la rueda del ratón también haga scroll sobre las franjas
          padding: isWide
              ? EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 24)
              : const EdgeInsets.fromLTRB(12, 8, 12, 16),
          sliver: SliverGrid(
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
            // Como GridView.builder, solo construye las tarjetas visibles,
            // así que pasarle los 993 de una búsqueda no cuesta nada
            delegate: SliverChildBuilderDelegate(
              (context, index) => PerfumeCard(
                key: ValueKey(entries[index].id),
                entry: entries[index],
                large: isWide,
              ),
              childCount: entries.length,
            ),
          ),
        ),
        if (footer != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: footer,
            ),
          ),
      ],
    );
  }

  Widget _buildMessage(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildError(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Error al cargar los perfumes.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
