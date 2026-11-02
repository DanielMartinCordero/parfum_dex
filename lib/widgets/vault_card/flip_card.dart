import 'dart:math' as math;
import 'package:flutter/material.dart';

// Cuánto crece el lado cercano al girar: 0.3 = un 15 % por cada lado
const double _perspectiveStrength = 0.3;

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width;
  final double height;
  final double borderRadius;
  final Color edgeColor;
  // Capa opcional encima de la tarjeta, por ejemplo la del modo edición
  final Widget? overlay;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.edgeColor,
    this.overlay,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  // Número que va de 0 (delante) a 1 (detrás) durante el giro
  late final AnimationController _controller;
  // El mismo número, pero arrancando y frenando suave
  late final Animation<double> _animation;

  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    _showFront = !_showFront;
    if (_showFront) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildFlippingCard(),
            // Va encima y no gira. Mientras esté puesta, recibe ella los toques
            if (widget.overlay != null)
              Positioned.fill(child: widget.overlay!),
          ],
        ),
      ),
    );
  }

  Widget _buildFlippingCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Depende del ancho real para que el giro se vea igual en móvil y PC
        final double perspective = _perspectiveStrength / constraints.maxWidth;

        return GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final double progress = _animation.value;
              final double angle = progress * math.pi;
              // A mitad del giro la tarjeta está de canto: ahí cambiamos de cara
              final bool frontVisible = progress < 0.5;
              // Alejamos la tarjeta al girar para que su borde cercano nunca
              // sea más alto que ella y no invada lo que tiene alrededor
              final double pullBack =
                  1 / (1 + _perspectiveStrength / 2 * math.sin(angle));

              return Stack(
                alignment: Alignment.center,
                children: [
                  if (progress > 0 && progress < 1)
                    _buildEdge(widget.height * pullBack),
                  Transform(
                    alignment: Alignment.center,
                    // setEntry añade la perspectiva, rotateY gira sobre el eje vertical
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..scaleByDouble(pullBack, pullBack, pullBack, 1)
                      ..rotateY(angle),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Offstage oculta sin destruir: las dos caras siguen cargadas
                        Offstage(
                          offstage: !frontVisible,
                          child: RepaintBoundary(child: widget.front),
                        ),
                        Offstage(
                          offstage: frontVisible,
                          child: _mirrored(
                            RepaintBoundary(child: widget.back),
                          ),
                        ),
                        if (progress > 0 && progress < 1)
                          frontVisible
                              ? _buildShine(progress)
                              : _mirrored(_buildShine(progress)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Canto de la tarjeta. Queda detrás y solo asoma cuando está de lado, para
  // que una tarjeta plana no desaparezca justo a los 90 grados
  Widget _buildEdge(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: widget.edgeColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // Lo que está detrás saldría en espejo: lo giramos media vuelta más
  Widget _mirrored(Widget child) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: child,
    );
  }

  // Franja de luz diagonal que cruza la tarjeta mientras gira
  Widget _buildShine(double progress) {
    // Máxima a mitad del giro, invisible al principio y al final
    final double strength = math.sin(progress * math.pi);
    // Posición de la franja: de fuera por la izquierda a fuera por la derecha
    final double position = -1.5 + 3 * progress;

    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(position - 1, -1),
              end: Alignment(position + 1, 1),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.65 * strength),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.3, 0.5, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}
