import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Sello de autor de David: una "D" con una chispa dorada dentro de una
/// insignia oscura. Es la marca que identifica todas sus apps, así que este
/// archivo se puede copiar tal cual a otra app para reutilizar el mismo sello.
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
  static const _top = Color(0xFF121624);
  static const _bottom = Color(0xFF2A2F45);
  static const _glyph = Color(0xFF8AB4FF);
  static const _spark = Color(0xFFFFD43B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    // Insignia (cuadrado muy redondeado) con degradado.
    final badge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 100),
      const Radius.circular(28),
    );
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(50, 0),
        const Offset(50, 100),
        const [_top, _bottom],
      );
    canvas.drawRRect(badge, bg);

    // Brillo suave arriba a la izquierda.
    canvas.save();
    canvas.clipRRect(badge);
    canvas.drawCircle(
      const Offset(26, 20),
      46,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.restore();

    final glyph = Paint()..color = _glyph;

    // Tronco de la D.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(34, 28, 46, 72),
        const Radius.circular(6),
      ),
      glyph,
    );

    // Panza de la D (media luna a la derecha).
    canvas.drawArc(
      const Rect.fromLTRB(19.2, 28, 85.2, 72),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = _glyph
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Chispa dorada.
    const sx = 72.0;
    const sy = 30.0;
    const r = 7.0;
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isEven ? r : r * 0.34;
      final a = math.pi / 2 + i * math.pi / 4;
      final p = Offset(sx + math.cos(a) * rr, sy - math.sin(a) * rr);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = _spark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MakerMarkPainter oldDelegate) => false;
}
