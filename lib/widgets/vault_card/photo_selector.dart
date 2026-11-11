import 'package:flutter/material.dart';

// Ventana pequeña que pregunta de dónde sacar la foto del frasco.
// Solo devuelve la elección: quien la abre es el que llama a PhotoService.
class PhotoSelector extends StatelessWidget {
  const PhotoSelector({super.key});

  // Abre la ventana y espera la respuesta:
  // true = cámara, false = galería, null = la cerró sin elegir
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const PhotoSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir foto', textAlign: TextAlign.center),
      content: Row(
        // Ocupa solo lo que necesitan los dos botones
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            icon: Icons.photo_camera_outlined,
            label: 'Cámara',
            isCamera: true,
          ),
          const SizedBox(width: 16),
          _buildOption(
            context,
            icon: Icons.photo_library_outlined,
            label: 'Galería',
            isCamera: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          // Sin valor: el show() devuelve null, igual que al tocar fuera
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  // Icono grande con su texto debajo. Al pulsarlo cierra la ventana
  // devolviendo si es la cámara o la galería
  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isCamera,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(isCamera),
      // El efecto al pulsar respeta las esquinas redondeadas
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.deepPurple.shade50,
              child: Icon(icon, size: 28, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
