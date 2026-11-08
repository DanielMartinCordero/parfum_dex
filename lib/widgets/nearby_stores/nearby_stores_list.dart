import 'package:flutter/material.dart';

import '../../models/nearby_store.dart';
import '../../services/map_services/distance_ranking/distance_ranking.dart';
import '../../utils/distance_format.dart';

/// Lista "cerca de ti": las tiendas ordenadas por distancia, con el mismo
/// número que su marcador en el mapa. Mientras se calculan las distancias
/// ([stores] es null) muestra una barra con el progreso.
class NearbyStoresList extends StatelessWidget {
  final List<RankedStore>? stores;

  // De 0 a 1 mientras se calcula; null si no se sabe todavía.
  final double? progress;

  final void Function(NearbyStore store) onStoreTap;

  const NearbyStoresList({
    super.key,
    required this.stores,
    required this.progress,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final ranked = stores;

    if (ranked == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // value: null dibuja una barra "indeterminada" que se mueve sola;
          // con un número dibuja exactamente ese porcentaje.
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 6),
          Text(
            'Calculando distancias…',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      );
    }

    final tiles = <Widget>[];
    for (var i = 0; i < ranked.length; i++) {
      final item = ranked[i];
      final store = item.store;

      tiles.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.deepPurple,
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            store.chain,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: _subtitle(store),
          trailing: Text(
            formatDistance(item.distanceKm),
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => onStoreTap(store),
        ),
      );
    }

    return Column(children: tiles);
  }

  /// Dirección y localidad en una línea, o nada si no hay ninguna.
  Widget? _subtitle(NearbyStore store) {
    final parts = <String>[];
    final address = store.address;
    final locality = store.locality;
    if (address != null) parts.add(address);
    if (locality != null) parts.add(locality);
    if (parts.isEmpty) return null;

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
