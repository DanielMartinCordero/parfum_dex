import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart'; // Añadimos el import de AppRoutes

import '../models/catalog_entry.dart';

/// Tarjeta vertical del catálogo: imagen, marca y nombre.
/// Se pinta con la entrada ligera del índice; precios, concentración y ml
/// se ven en el detalle, que lee el perfume completo.
class PerfumeCard extends StatelessWidget {
  final CatalogEntry entry;

  // true en pantallas grandes (PC): textos y márgenes más grandes
  final bool large;

  const PerfumeCard({super.key, required this.entry, this.large = false});

  @override
  Widget build(BuildContext context) {
    final double padding = large ? 12 : 8;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        // Al tocar, navegamos solo con el ID: el detalle lee el perfume completo
        onTap: () {
          // Usamos interpolación de strings para construir la ruta dinámicamente
          context.go('${AppRoutes.explore}/detail/${entry.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            Expanded(
              flex: 5,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 4),
                child: Hero(
                  tag: 'perfume-${entry.id}', // Usamos el ID único
                  child: Image.network(
                    entry.imageUrl,
                    fit: BoxFit.contain,
                    // En web, si el servidor de la imagen no permite CORS,
                    // la pinta como una etiqueta <img> normal
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),

            // Datos (en grande la imagen gana más espacio: 5/7 en vez de 5/9)
            Expanded(
              flex: large ? 2 : 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, 4, padding, padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: large ? 12 : 10,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.name,
                      // La tarjeta grande es más ancha: con 2 líneas basta
                      maxLines: large ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: large ? 15 : 12,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
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
