import 'dart:math';

import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  // Si es null, Flutter dibuja el botón deshabilitado (en gris)
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      ),
      label: const Text('Continuar con Google', style: TextStyle(fontSize: 16)),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Igual que los ElevatedButton del tema
        ),
      ),
    );
  }
}

// Dibuja la "G" de Google con sus cuatro colores, sin imágenes ni paquetes.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;

    // El arco se dibuja sobre el centro del trazo, así que encogemos el
    // rectángulo medio trazo por cada lado para que no se salga del icono.
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    // Ángulos en grados: 0 = derecha y crecen en el sentido del reloj.
    void arc(double startDeg, double sweepDeg, Color color) {
      canvas.drawArc(
        rect,
        startDeg * pi / 180,
        sweepDeg * pi / 180,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    arc(0, 45, _blue); // abajo a la derecha
    arc(45, 90, _green); // abajo
    arc(135, 70, _yellow); // izquierda
    arc(205, 115, _red); // arriba (deja un hueco a la derecha: la boca de la G)

    // La barra horizontal azul, del centro hasta el borde derecho
    final center = rect.center;
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        size.width,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
