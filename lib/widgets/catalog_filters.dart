import 'package:flutter/material.dart';

// Filtros del catálogo (género y temporada). Aquí solo está la parte
// visual: qué filtro está marcado y la consulta a Firestore los lleva
// ExploreScreen, que recibe los cambios por onGenreChanged/onSeasonChanged

// Valores guardados en Firestore -> texto del chip. Son los únicos que
// admite el seeder (GENRES y SEASONS en tools/seeder/seed.mjs)
const Map<String, String> _genreLabels = {
  'male': 'Hombre',
  'female': 'Mujer',
  'unisex': 'Unisex',
};
const Map<String, String> _seasonLabels = {
  'spring': 'Primavera',
  'summer': 'Verano',
  'fall': 'Otoño',
  'winter': 'Invierno',
};

// Panel izquierdo en PC: título y debajo los filtros que recibe
class CatalogFiltersPanel extends StatelessWidget {
  final Widget child;

  const CatalogFiltersPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// Chips de género y temporada. Solo pinta y avisa: el estado (qué está
// marcado) lo guarda la pantalla, que es quien lanza la consulta
class CatalogFilters extends StatelessWidget {
  final String? genre;
  final String? season;
  final bool vertical; // true: panel de PC, false: filas bajo el buscador
  final bool enabled;
  final ValueChanged<String?> onGenreChanged;
  final ValueChanged<String?> onSeasonChanged;

  const CatalogFilters({
    super.key,
    required this.genre,
    required this.season,
    required this.vertical,
    required this.enabled,
    required this.onGenreChanged,
    required this.onSeasonChanged,
  });

  // Un chip por cada valor. Al pulsar el que ya estaba marcado, se
  // desmarca y se avisa con null (sin filtro)
  List<Widget> _chips(
    Map<String, String> labels,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    return [
      for (final MapEntry<String, String> option in labels.entries)
        ChoiceChip(
          label: Text(option.value),
          selected: selected == option.key,
          // onSelected a null deja el chip desactivado (gris)
          onSelected: enabled
              ? (isSelected) => onChanged(isSelected ? option.key : null)
              : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final genreChips = _chips(_genreLabels, genre, onGenreChanged);
    final seasonChips = _chips(_seasonLabels, season, onSeasonChanged);

    // Móvil: dos filas que se desplazan en horizontal si no caben
    if (!vertical) {
      return Column(
        children: [
          _ChipRow(chips: genreChips),
          _ChipRow(chips: seasonChips),
          const SizedBox(height: 4),
        ],
      );
    }

    // PC: cada grupo con su título, y los chips saltan de línea (Wrap)
    final TextStyle? titleStyle = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Género', style: titleStyle),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: genreChips),
        const SizedBox(height: 20),
        Text('Temporada', style: titleStyle),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: seasonChips),
        if (!enabled) ...[
          const SizedBox(height: 16),
          Text(
            'Los filtros se aplican al catálogo, no a la búsqueda.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}

// Fila de chips con scroll horizontal (móvil)
class _ChipRow extends StatelessWidget {
  final List<Widget> chips;

  const _ChipRow({required this.chips});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          for (final Widget chip in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }
}
