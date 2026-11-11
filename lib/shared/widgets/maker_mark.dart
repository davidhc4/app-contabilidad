import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Sello de autor de David: una "D" clara sobre una insignia oscura. No es el
/// ícono de la app; es la marca que identifica las apps hechas por él, así
/// que este archivo se puede copiar tal cual a otra app para usar el mismo
/// sello.
///
/// Está dibujado con código (no es una imagen), por lo que se ve nítido en
/// cualquier tamaño y en cualquier celular.
class MakerMark extends StatelessWidget {
  final double size;
  const MakerMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MakerMarkPainter()),
    );
  }
}

class _MakerMarkPainter extends CustomPainter {
  static const _top = Color(0xFF181A20);
  static const _bottom = Color(0xFF0E0F13);
  static const _border = Color(0xFF3A3F4B);
  static const _glyph = Color(0xFFF2F3F5);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    // Insignia oscura con un borde fino.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(24),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(50, 0),
          const Offset(50, 100),
          const [_top, _bottom],
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2.25, 2.25, 95.5, 95.5),
        const Radius.circular(21.75),
      ),
      Paint()
        ..color = _border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Tronco de la D.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(30, 27, 41, 73),
        const Radius.circular(2),
      ),
      Paint()..color = _glyph,
    );

    // Panza de la D: medio anillo, separado del tronco.
    canvas.drawArc(
      const Rect.fromLTRB(28, 32.5, 66, 67.5),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = _glyph
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MakerMarkPainter oldDelegate) => false;
}
