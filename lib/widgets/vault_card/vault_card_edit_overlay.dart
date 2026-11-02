import 'package:flutter/material.dart';

// Capa oscura que se pone sobre la tarjeta en el modo edición
class VaultCardEditOverlay extends StatelessWidget {
  final double borderRadius;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VaultCardEditOverlay({
    super.key,
    required this.borderRadius,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: Colors.grey.shade900.withValues(alpha: 0.8),
        // Abajo, sobre la barra, para no tapar la foto ni el nombre del perfume
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
