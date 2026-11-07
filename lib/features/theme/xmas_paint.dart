import 'dart:math' as math;

import 'package:flutter/material.dart';

const _twoPi = math.pi * 2;

/// Nieve que cae. [t] va de 0 a 1 y se repite sin saltos: cada copo da un
/// número entero de vueltas por ciclo.
void paintSnow(
  Canvas canvas,
  Size size,
  double t, {
  int count = 60,
  double maxRadius = 3.4,
  double alpha = 0.9,
  int seed = 7,
}) {
  final rng = math.Random(seed);
  final paint = Paint();
  for (var i = 0; i < count; i++) {
    final x0 = rng.nextDouble();
    final y0 = rng.nextDouble();
    final size01 = rng.nextDouble();
    final radius = 1 + size01 * (maxRadius - 1);
    final fall = size01 > 0.66 ? 3 : (size01 > 0.33 ? 2 : 1);
    final sway = 6 + rng.nextDouble() * 12;
    final swayCycles = 2 + rng.nextInt(3);
    final phase = rng.nextDouble() * _twoPi;
    final y = ((y0 + t * fall) % 1.0) * (size.height + 24) - 12;
    final x = x0 * size.width + math.sin(_twoPi * t * swayCycles + phase) * sway;
    paint.color = Colors.white.withValues(alpha: alpha * (0.35 + 0.65 * size01));
    canvas.drawCircle(Offset(x, y), radius, paint);
  }
}

const _bulbColors = [
  Color(0xFFFF3B3B),
  Color(0xFFFFD43B),
  Color(0xFF3DDC84),
  Color(0xFF4DA3FF),
];

/// Guirnalda de luces que cuelga del borde de arriba y titila.
void paintLights(Canvas canvas, double width, double top, double t) {
  final segments = math.max(3, (width / 110).round());
  final segWidth = width / segments;
  const sag = 16.0;
  final wire = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = const Color(0xFF2F7D4F).withValues(alpha: 0.85);
  final path = Path()..moveTo(0, top);
  for (var s = 0; s < segments; s++) {
    path.quadraticBezierTo(
      segWidth * (s + 0.5), top + sag * 2, segWidth * (s + 1), top);
  }
  canvas.drawPath(path, wire);

  var index = 0;
  for (var s = 0; s < segments; s++) {
    final p0 = Offset(segWidth * s, top);
    final c = Offset(segWidth * (s + 0.5), top + sag * 2);
    final p2 = Offset(segWidth * (s + 1), top);
    for (var k = 1; k <= 3; k++) {
      final u = k / 4;
      final pos = p0 * ((1 - u) * (1 - u)) + c * (2 * (1 - u) * u) + p2 * (u * u);
      final color = _bulbColors[index % _bulbColors.length];
      final twinkle = 0.55 + 0.45 * math.sin(_twoPi * (t * 2 + index * 0.37));
      final bulb = pos + const Offset(0, 7);
      canvas.drawCircle(bulb, 10, Paint()..color = color.withValues(alpha: 0.12 * twinkle));
      canvas.drawCircle(bulb, 6, Paint()..color = color.withValues(alpha: 0.28 * twinkle));
      canvas.drawOval(
        Rect.fromCenter(center: bulb, width: 5, height: 8),
        Paint()..color = color.withValues(alpha: 0.55 + 0.45 * twinkle),
      );
      canvas.drawRect(
        Rect.fromCenter(center: pos + const Offset(0, 1.5), width: 3, height: 3),
        Paint()..color = const Color(0xFF3A3A3A),
      );
      index++;
    }
  }
}

/// Ramita de acebo: tres hojas y tres bayas rojas.
void paintHolly(Canvas canvas, Offset origin, double scale, double rotation) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.rotate(rotation);
  canvas.scale(scale);
  final leaf = Paint()..color = const Color(0xFF1F8A4C);
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = const Color(0xFF0F5A30);
  for (final a in [-0.95, 0.0, 0.95]) {
    canvas.save();
    canvas.rotate(a);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(26, -22, 62, 0)
      ..quadraticBezierTo(26, 22, 0, 0);
    canvas.drawPath(path, leaf);
    canvas.drawPath(path, edge);
    canvas.drawLine(const Offset(4, 0), const Offset(52, 0), edge);
    canvas.restore();
  }
  for (final o in const [Offset(-4, -4), Offset(5, 3), Offset(-3, 7)]) {
    canvas.drawCircle(o, 6, Paint()..color = const Color(0xFFD7263D));
    canvas.drawCircle(o + const Offset(-1.8, -1.8), 1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.7));
  }
  canvas.restore();
}

/// Estrella de cinco puntas.
Path starPath(Offset c, double r, {double turn = 0}) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * 0.45;
    final a = -math.pi / 2 + turn + i * math.pi / 5;
    final p = c + Offset(math.cos(a), math.sin(a)) * rr;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// Estrella dorada de neón que late.
void paintNeonStar(Canvas canvas, Offset c, double r, double t) {
  final pulse = 0.5 + 0.5 * math.sin(_twoPi * t);
  final path = starPath(c, r);
  const gold = Color(0xFFFFD43B);
  Paint stroke(double width, Color color, double blur) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..color = color
    ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;
  canvas.drawPath(path, stroke(r * 0.2, gold.withValues(alpha: 0.35 + 0.25 * pulse), 8 + 4 * pulse));
  canvas.drawPath(path, stroke(r * 0.1, gold.withValues(alpha: 0.8), 3));
  canvas.drawPath(path, stroke(r * 0.04, const Color(0xFFFFF6CC), 0));
}

/// Destellos de cuatro puntas que titilan.
void paintSparkles(Canvas canvas, Size size, double t, {int count = 12, int seed = 3}) {
  final rng = math.Random(seed);
  for (var i = 0; i < count; i++) {
    final c = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
    final phase = rng.nextDouble();
    final twinkle = math.max(0.0, math.sin(_twoPi * (t * 2 + phase)));
    final r = (2 + rng.nextDouble() * 4) * (0.4 + 0.6 * twinkle);
    final paint = Paint()
      ..color = const Color(0xFFFFF3B0).withValues(alpha: 0.2 + 0.8 * twinkle)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), paint);
    canvas.drawLine(c - Offset(0, r), c + Offset(0, r), paint);
  }
}
