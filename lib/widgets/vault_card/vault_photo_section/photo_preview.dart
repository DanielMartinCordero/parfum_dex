import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

class PhotoPreview extends StatelessWidget {
  final Uint8List? photo;
  final String imageUrl; // la del catálogo, si no hay foto
  final bool isLoading;
  final String? error;
  final bool showSettingsButton;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const PhotoPreview({
    super.key,
    required this.photo,
    required this.imageUrl,
    required this.isLoading,
    required this.error,
    required this.showSettingsButton,
    required this.onPick,
    required this.onRemove,
  });

  Widget build(BuildContext context) {
    final String? error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildThumbnail(photo),
            const SizedBox(width: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onPick,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            photo == null ? 'Añadir foto' : 'Cambiar foto',
                          ),
                        ),
                        if (photo != null)
                          TextButton.icon(
                            onPressed: onRemove,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Quitar foto'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
          if (showSettingsButton)
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Abrir ajustes'),
            ),
        ],
      ],
    );
  }

  Widget _buildThumbnail(Uint8List? photo) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias, // recorta la foto con las esquinas
      child: photo != null
          ? Image.memory(
              photo,
              fit: BoxFit.cover,
              gaplessPlayback: true, // al cambiarla no parpadea en blanco
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image_outlined,
                color: Colors.grey.shade400,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
    );
  }
}
