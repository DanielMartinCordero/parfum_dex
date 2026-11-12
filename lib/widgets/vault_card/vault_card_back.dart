import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../models/perfume.dart';
import '../../models/vault_item.dart';
import '../../services/perfumes_service.dart';

class VaultCardBack extends StatefulWidget {
  final VaultItem item;

  const VaultCardBack({
    super.key,
    required this.item,
  });

  @override
  State<VaultCardBack> createState() => _VaultCardBackState();
}

class _VaultCardBackState extends State<VaultCardBack> {
  final PerfumesService _perfumesService = PerfumesService();

  // Guardamos el Future para no repetir la lectura en cada rebuild
  late Future<Perfume?> _perfumeFuture;

  // Color dorado para el borde y la barra
  final Color _accentColor = Colors.amber.shade200;

  @override
  void initState() {
    super.initState();
    _perfumeFuture = _perfumesService.getPerfumeById(widget.item.perfumeId);
  }

  @override
  void didUpdateWidget(covariant VaultCardBack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La lista puede reutilizar esta tarjeta para otro perfume
    if (oldWidget.item.perfumeId != widget.item.perfumeId) {
      _perfumeFuture = _perfumesService.getPerfumeById(widget.item.perfumeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // La tarjeta tiene altura fija: limitamos el zoom de texto del sistema
    // para que los datos no se salgan por abajo
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.05,
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    final VaultItem item = widget.item;
    // Usamos directamente el fillPercentage (ahora asegurado en el modelo de no ser nulo)
    final double fillPercentage = item.fillPercentage;
    // Sin capacidad no hay barra de ml (variable local para no usar "!")
    final int? capacity = item.capacityMl;
    final double? costPerSpray =
        item.purchasePrice != null ? item.costPerSpray : null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shadowColor: Colors.deepPurple,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _accentColor, width: 1.5),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade500,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // PISO 1: datos, foto y flecha
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Datos del perfume
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.brand.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Precio: ',
                            item.purchasePrice != null
                                ? '${item.purchasePrice!.toStringAsFixed(2)} €'
                                : 'Sin precio',
                          ),
                          _buildInfoRow(
                            'Coste/spray: ',
                            costPerSpray != null
                                ? '${costPerSpray.toStringAsFixed(3)} €'
                                : '—',
                          ),
                          _buildInfoRow(
                            'Valoración: ',
                            item.rating != null
                                ? '${item.rating!.toStringAsFixed(1)} / 5'
                                : '—',
                          ),
                          _buildInfoRow(
                            'Añadido: ',
                            _formatDate(item.addedAt),
                          ),
                          const SizedBox(height: 6),
                          _buildNotes(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 2. Imagen (aquí irá la foto del usuario)
                    Container(
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildPhoto(item),
                    ),
                    const SizedBox(width: 8),

                    // 3. Icono de flecha
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              // PISO 2: barra de progreso y ml (solo si conocemos la capacidad)
              if (capacity != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fillPercentage,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          color: _accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(item.remainingMl ?? capacity).toStringAsFixed(0)} / $capacity ml',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Fila con una etiqueta a la izquierda y su valor a la derecha
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Muestra las notas cuando llegan de Firestore. Mientras carga, o si no hay
  // notas, no pinta nada para no ensuciar la tarjeta.
  Widget _buildNotes() {
    return FutureBuilder<Perfume?>(
      future: _perfumeFuture,
      builder: (context, snapshot) {
        final List<String> notes = snapshot.data?.mainNotes ?? [];
        if (notes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea 1: icono y título
            Row(
              children: [
                Icon(Icons.spa_outlined, size: 15, color: _accentColor),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    "Notas principales: ",
                    style: TextStyle(fontSize: 12, color: _accentColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Línea 2: las notas
            Text(
              notes.join(' · '),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _accentColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
  // Foto del usuario si la tiene; si no, la del catálogo
  Widget _buildPhoto(VaultItem item) {
    // Copia local: así Dart sabe que tras comprobarla ya no es null
    final Uint8List? photo = item.userBottlePhoto;

    if (photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          photo,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image_outlined,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.network(
        item.imageUrl,
        fit: BoxFit.contain,
        // En web, sin cabeceras CORS se pinta como <img> normal
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
