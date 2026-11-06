import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Un "mapa" dibujado y desenfocado que hace de fondo antes de buscar.
///
/// Se dibuja con un CustomPainter a propósito: no carga teselas ni imágenes,
/// así que abrir la ficha de un perfume no hace ninguna petición de red.
class BlurredMapPlaceholder extends StatelessWidget {
  final Widget? child;

  const BlurredMapPlaceholder({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter:
          ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5, tileMode: TileMode.clamp), //5 de fuerza de desenfoque
          child: const CustomPaint(painter: _FakeMapPainter()),
        ),
        // Velo claro para que el contenido de encima se lea bien.
        ColoredBox(color: Colors.white.withValues(alpha: 0.35)),
        if (child != null) Center(child: child),
      ],
    );
  }
}

class _FakeMapPainter extends CustomPainter {
  const _FakeMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF2EFE9));

    // Parque y agua.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.55, w * 0.22, h * 0.32),
          const Radius.circular(18)),
      Paint()..color = const Color(0xFFCFE6C4),
    );
    final river = Path()
    //Medidas proporcionales, se ajusta a cualquier dispositivo
      ..moveTo(w * 0.62, 0)
      ..cubicTo(w * 0.55, h * 0.3, w * 0.85, h * 0.55, w * 0.72, h);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFB9D7EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22,
    );

    // Calles: cuadrícula ligeramente irregular + dos avenidas.
    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    //Aplicamos un random para que no se vea siempre igual
    final rng = math.Random(3);
    for (var x = w * 0.05; x < w; x += w * 0.14) {
      final dx = (rng.nextDouble() - 0.5) * 18;
      canvas.drawLine(Offset(x, 0), Offset(x + dx, h), street);
    }
    for (var y = h * 0.1; y < h; y += h * 0.2) {
      final dy = (rng.nextDouble() - 0.5) * 14;
      canvas.drawLine(Offset(0, y), Offset(w, y + dy), street);
    }
    final avenue = Paint()
      ..color = const Color(0xFFFCE7B2)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.85), Offset(w, h * 0.2), avenue);
    canvas.drawLine(Offset(w * 0.2, 0), Offset(w * 0.45, h), avenue);

    // Marcadores.
    final pin = Paint()..color = Colors.deepPurple;
    for (final p in const [Offset(0.3, 0.35), Offset(0.52, 0.62), Offset(0.78, 0.3), Offset(0.88, 0.75)]) {
      canvas.drawCircle(Offset(p.dx * w, p.dy * h), 9, pin);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
