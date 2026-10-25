import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/silhouettes.dart';
import 'skins.dart';

const _twoPi = math.pi * 2;
const _orangeTop = Color(0xFFFF8A1F);
const _orangeBottom = Color(0xFFE85D04);

/// Lo que un aspecto le aporta a la tarjeta en un instante dado.
class SkinFrame {
  /// Sombras (luz) que rodean la tarjeta.
  final List<BoxShadow> shadows;

  /// Colores de fondo si el aspecto los cambia.
  final List<Color>? gradient;

  /// Se pinta sobre el fondo y debajo del contenido.
  final Widget? underlay;

  /// Se pinta sobre el fondo y debajo del texto.
  final Widget? overlay;

  const SkinFrame({
    this.shadows = const [],
    this.gradient,
    this.underlay,
    this.overlay,
  });
}

/// Anima un aspecto y le entrega a [builder] lo que toca dibujar en cada
/// instante. Sin aspecto (o sin animación) entrega un cuadro fijo.
class SkinFx extends StatefulWidget {
  final Skin? skin;
  final bool animate;
  final BorderRadius radius;
  final Color baseStart;
  final Color baseEnd;
  final Widget Function(BuildContext context, SkinFrame frame) builder;

  const SkinFx({
    super.key,
    required this.skin,
    required this.radius,
    required this.baseStart,
    required this.baseEnd,
    required this.builder,
    this.animate = true,
  });

  @override
  State<SkinFx> createState() => _SkinFxState();
}

class _SkinFxState extends State<SkinFx> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Duration? _period;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant SkinFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  static Duration? _periodOf(Skin? skin, bool animate) {
    if (skin == null || !animate) return null;
    switch (skin.family) {
      case SkinFamily.halo:
        return Duration(milliseconds: skin.rarity == Rarity.legendario ? 3000 : 4200);
      case SkinFamily.brillo:
        return const Duration(milliseconds: 5200);
      case SkinFamily.grafiti:
        final neon = skin.rarity != Rarity.comun &&
            skin.rarity != Rarity.pocoComun &&
            skin.rarity != Rarity.raro;
        return neon ? const Duration(milliseconds: 3600) : null;
      case SkinFamily.telarana:
      case SkinFamily.murcielago:
        return const Duration(milliseconds: 4000);
      case SkinFamily.imagen:
        return null;
    }
  }

  void _sync() {
    final period = _periodOf(widget.skin, widget.animate);
    if (period == _period) return;
    _period = period;
    _controller?.dispose();
    _controller = null;
    if (period != null) {
      _controller = AnimationController(vsync: this, duration: period)..repeat();
    }
  }

  SkinFrame _frame(double t) {
    final skin = widget.skin;
    if (skin == null) return const SkinFrame();
    return skinFrame(skin, t, widget.radius, widget.baseStart, widget.baseEnd);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return widget.builder(context, _frame(0.25));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => widget.builder(context, _frame(controller.value)),
    );
  }
}

/// Calcula cómo se ve un aspecto en el instante [t] (0 a 1, se repite).
SkinFrame skinFrame(
  Skin skin,
  double t,
  BorderRadius radius,
  Color baseStart,
  Color baseEnd,
) {
  final k = skin.rarity.intensity;
  final c = skin.color;
  final wave = 0.5 + 0.5 * math.sin(_twoPi * t);

  switch (skin.family) {
    case SkinFamily.halo:
      final glow = 0.55 + 0.45 * wave;
      return SkinFrame(
        shadows: [
          BoxShadow(
            color: c.withValues(alpha: (0.16 + 0.5 * k) * glow),
            blurRadius: 10 + 30 * k,
            spreadRadius: 1 + 5 * k * wave,
          ),
          if (k >= 0.8)
            BoxShadow(
              color: Color.lerp(c, Colors.white, 0.35)!
                  .withValues(alpha: 0.35 * k * glow),
              blurRadius: 60,
              spreadRadius: 6 * wave,
            ),
        ],
      );

    case SkinFamily.brillo:
      final tint = 0.2 + 0.5 * k;
      return SkinFrame(
        gradient: [
          Color.lerp(baseStart, c, tint)!,
          Color.lerp(baseEnd, c, tint * 0.7)!,
        ],
        shadows: [
          BoxShadow(
            color: c.withValues(alpha: (0.1 + 0.3 * k) * (0.6 + 0.4 * wave)),
            blurRadius: 16 + 14 * k,
          ),
        ],
        overlay: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: RadialGradient(
                center: Alignment(
                  1.2 * math.sin(_twoPi * t),
                  0.4 * math.cos(_twoPi * t),
                ),
                radius: 0.8 + 0.4 * k,
                colors: [
                  Colors.white.withValues(alpha: (0.06 + 0.22 * k) * (0.6 + 0.4 * wave)),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
              border: Border.all(
                color: c.withValues(alpha: (0.25 + 0.55 * k) * (0.5 + 0.5 * wave)),
                width: 1.2 + 1.8 * k,
              ),
            ),
          ),
        ),
      );

    case SkinFamily.grafiti:
      final neon = skin.rarity != Rarity.comun &&
          skin.rarity != Rarity.pocoComun &&
          skin.rarity != Rarity.raro;
      return SkinFrame(
        shadows: neon
            ? [
                BoxShadow(
                  color: c.withValues(
                    alpha: skin.rarity == Rarity.epico ? 0.12 : 0.28,
                  ),
                  blurRadius: 22,
                ),
              ]
            : const [],
        overlay: IgnorePointer(
          child: CustomPaint(
            painter: GrafitiPainter(
              design: skin.design ?? 'xd',
              color: c,
              rarity: skin.rarity,
              t: t,
            ),
          ),
        ),
      );

    case SkinFamily.telarana:
      return SkinFrame(
        gradient: const [_orangeTop, _orangeBottom],
        shadows: [
          BoxShadow(color: _orangeBottom.withValues(alpha: 0.4), blurRadius: 18),
        ],
        underlay: IgnorePointer(
          child: CustomPaint(painter: _WebSkinPainter(t)),
        ),
      );

    case SkinFamily.murcielago:
      return SkinFrame(
        gradient: const [_orangeTop, _orangeBottom],
        shadows: [
          BoxShadow(color: _orangeBottom.withValues(alpha: 0.4), blurRadius: 18),
        ],
        underlay: IgnorePointer(
          child: CustomPaint(painter: _BatSkinPainter(t)),
        ),
      );

    case SkinFamily.imagen:
      return const SkinFrame();
  }
}

/// Negro y blanco que se mezclan suavemente.
Color _blackWhite(double t, {bool inverse = false}) {
  var p = 0.5 + 0.5 * math.sin(_twoPi * t);
  if (inverse) p = 1 - p;
  return Color.lerp(const Color(0xFF0B0B10), const Color(0xFFF8F8F8), p)!;
}

class _WebSkinPainter extends CustomPainter {
  final double t;
  _WebSkinPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final center = Offset(size.width * 0.76, h * 0.52);
    final radius = h * 0.62;
    final paint = Paint()
      ..color = _blackWhite(t).withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, h / 110);

    const spokes = 10;
    Offset point(int i, double r) {
      final a = _twoPi * i / spokes + 0.2;
      return center + Offset(math.cos(a), math.sin(a)) * r;
    }

    for (var i = 0; i < spokes; i++) {
      canvas.drawLine(center, point(i, radius), paint);
    }
    for (var ring = 1; ring <= 5; ring++) {
      final r = radius * ring / 5;
      final path = Path()..moveTo(point(0, r).dx, point(0, r).dy);
      for (var i = 0; i < spokes; i++) {
        final p2 = point(i + 1, r);
        final mid = (point(i, r) + p2) / 2;
        final control = mid + (center - mid) * 0.16;
        path.quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy);
      }
      canvas.drawPath(path, paint);
    }

    // Una arañita que cuelga y se mece.
    final x = size.width * 0.9;
    final y = h * (0.2 + 0.05 * math.sin(_twoPi * t));
    final ink = _blackWhite(t, inverse: true);
    final thread = Paint()
      ..color = ink.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, 0), Offset(x, y), thread);
    final leg = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final dy = (i - 1.5) * 3.2;
      canvas.drawLine(Offset(x, y + dy * 0.4), Offset(x - 9, y + dy - 3), leg);
      canvas.drawLine(Offset(x, y + dy * 0.4), Offset(x + 9, y + dy - 3), leg);
    }
    canvas.drawCircle(Offset(x, y), 4.6, Paint()..color = ink);
    canvas.drawCircle(Offset(x, y - 5), 3, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(covariant _WebSkinPainter old) => old.t != t;
}

class _BatSkinPainter extends CustomPainter {
  final double t;
  _BatSkinPainter(this.t);

  void _bat(Canvas canvas, Offset center, double width, double flap, Color c) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, flap);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: width * 0.75,
    );
    canvas.drawPath(kBat.path(rect), Paint()..color = c);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final color = _blackWhite(t);
    final flap = 0.92 + 0.08 * math.sin(_twoPi * t * 2);
    _bat(canvas, Offset(size.width * 0.72, h * 0.5), h * 1.05, flap, color);
    _bat(canvas, Offset(size.width * 0.93, h * 0.2), h * 0.34, flap,
        color.withValues(alpha: 0.7));
    _bat(canvas, Offset(size.width * 0.5, h * 0.86), h * 0.28, flap,
        color.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _BatSkinPainter old) => old.t != t;
}

/// Dibuja los grafitis sobre la tarjeta.
class GrafitiPainter extends CustomPainter {
  final String design;
  final Color color;
  final Rarity rarity;
  final double t;

  GrafitiPainter({
    required this.design,
    required this.color,
    required this.rarity,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (design) {
      case 'xd':
        _text(canvas, 'XD', Offset(w * 0.72, h * 0.5), h * 0.62, -0.2, bold: true);
        _text(canvas, 'xd', Offset(w * 0.14, h * 0.66), h * 0.2, 0.15, alpha: 0.8);
        _text(canvas, ':v', Offset(w * 0.46, h * 0.14), h * 0.17, -0.1, alpha: 0.8);
      case 'sus':
        _text(canvas, 'sus', Offset(w * 0.7, h * 0.52), h * 0.46, 0.12,
            bold: true, italic: true);
        _text(canvas, '👀', Offset(w * 0.86, h * 0.2), h * 0.26, -0.15);
        _text(canvas, '¿?', Offset(w * 0.5, h * 0.8), h * 0.2, 0.1, alpha: 0.85);
      case 'idea':
        _text(canvas, '¿qué?', Offset(w * 0.66, h * 0.42), h * 0.34, -0.1, bold: true);
        _text(canvas, '🤷', Offset(w * 0.8, h * 0.72), h * 0.3, 0.1);
        _text(canvas, 'meh', Offset(w * 0.45, h * 0.12), h * 0.15, 0.05, alpha: 0.8);
      case 'estrellas':
        const stars = [
          [0.82, 0.25, 0.12],
          [0.64, 0.6, 0.08],
          [0.9, 0.7, 0.1],
          [0.55, 0.22, 0.05],
          [0.74, 0.88, 0.06],
          [0.96, 0.46, 0.05],
        ];
        for (var i = 0; i < stars.length; i++) {
          _star(canvas, Offset(w * stars[i][0], h * stars[i][1]), h * stars[i][2],
              i * 0.4);
        }
      case 'zigzag':
        for (var i = 0; i < 3; i++) {
          final y = h * (0.3 + 0.2 * i);
          final path = Path()..moveTo(w * 0.5, y);
          for (var j = 1; j <= 8; j++) {
            path.lineTo(w * (0.5 + 0.06 * j), y + (j.isOdd ? -h * 0.05 : h * 0.05));
          }
          canvas.drawPath(
            path,
            Paint()
              ..color = color.withValues(alpha: 0.9 - i * 0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = h * 0.035
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
      case 'lunares':
        for (var i = 0; i < 6; i++) {
          for (var j = 0; j < 5; j++) {
            final seed = (i * 7 + j * 13) % 5;
            final r = h * (0.014 + 0.012 * seed);
            canvas.drawCircle(
              Offset(w * (0.5 + 0.09 * i) + (j.isOdd ? w * 0.04 : 0), h * (0.12 + 0.19 * j)),
              r,
              Paint()..color = color.withValues(alpha: 0.85),
            );
          }
        }
      case 'ondas':
        _waves(canvas, size);
      case 'montes':
        _mountains(canvas, size);
      case 'geo':
        _geometric(canvas, size);
      default:
        _neon(canvas, size);
    }
  }

  // ---- grafitis simples ----

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    double angle, {
    double alpha = 1,
    bool bold = false,
    bool italic = false,
  }) {
    TextPainter build(Paint? foreground) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              foreground: foreground,
              color: foreground == null ? color.withValues(alpha: alpha) : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

    final outline = build(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * 0.12
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xCC000000),
    );
    final fill = build(null);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final offset = Offset(-fill.width / 2, -fill.height / 2);
    outline.paint(canvas, offset);
    fill.paint(canvas, offset);
    canvas.restore();
  }

  void _star(Canvas canvas, Offset c, double r, double turn) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + turn + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.92));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x99000000),
    );
  }

  // ---- grafitis serios ----

  void _waves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (var layer = 0; layer < 4; layer++) {
      final base = h * (0.52 + 0.12 * layer);
      final amp = h * (0.05 - 0.006 * layer);
      final path = Path()..moveTo(0, h);
      final line = Path();
      for (var i = 0; i <= 40; i++) {
        final x = w * i / 40;
        final y = base + amp * math.sin(i / 40 * math.pi * (3 + layer) + layer);
        path.lineTo(x, y);
        i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.14 + 0.07 * layer));
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = color.withValues(alpha: 0.9 - 0.15 * layer),
      );
    }
  }

  void _mountains(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.3),
      h * 0.13,
      Paint()..color = color.withValues(alpha: 0.95),
    );
    const layers = [
      [0.3, 0.62, 0.5, 0.78, 0.7, 0.58, 1.0, 0.8],
      [0.0, 0.8, 0.22, 0.58, 0.45, 0.85, 0.7, 0.62, 1.0, 0.84],
      [0.0, 0.92, 0.3, 0.74, 0.6, 0.94, 0.85, 0.78, 1.0, 0.9],
    ];
    for (var l = 0; l < layers.length; l++) {
      final pts = layers[l];
      final path = Path()..moveTo(w * pts[0], h);
      for (var i = 0; i + 1 < pts.length; i += 2) {
        path.lineTo(w * pts[i], h * pts[i + 1]);
      }
      path.lineTo(w, h);
      path.close();
      final shade = Color.lerp(color, Colors.black, 0.55 - 0.2 * l)!;
      canvas.drawPath(path, Paint()..color = shade.withValues(alpha: 0.55 + 0.15 * l));
    }
  }

  void _geometric(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w * 0.76, h * 0.5);
    for (var i = 0; i < 6; i++) {
      final side = h * 0.72 * (1 - i * 0.14);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * math.pi / 14);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color.withValues(alpha: 0.95 - i * 0.1),
      );
      canvas.restore();
    }
    final thin = Paint()
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.4);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w, h * 0.55), thin);
    canvas.drawLine(Offset(w * 0.6, h), Offset(w, h * 0.2), thin);
    canvas.drawCircle(c, h * 0.04, Paint()..color = color);
  }

  // ---- neón ----

  Path _shape(String key, Rect r) {
    Offset p(double x, double y) => Offset(r.left + x * r.width, r.top + y * r.height);
    final path = Path();
    switch (key) {
      case 'rayo':
        final pts = [
          p(0.6, 0), p(0.2, 0.56), p(0.47, 0.56), p(0.36, 1),
          p(0.82, 0.4), p(0.55, 0.4), p(0.72, 0), //
        ];
        path.moveTo(pts.first.dx, pts.first.dy);
        for (final o in pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        path.close();
        for (final s in [
          [0.08, 0.2, 0.0, 0.3],
          [0.92, 0.7, 1.0, 0.8],
        ]) {
          path.moveTo(p(s[0], s[1]).dx, p(s[0], s[1]).dy);
          path.lineTo(p(s[2], s[3]).dx, p(s[2], s[3]).dy);
        }
      case 'corona':
        final pts = [
          p(0.0, 0.8), p(0.05, 0.2), p(0.28, 0.5), p(0.5, 0.05),
          p(0.72, 0.5), p(0.95, 0.2), p(1.0, 0.8), //
        ];
        path.moveTo(pts.first.dx, pts.first.dy);
        for (final o in pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        path.close();
        path.moveTo(p(0.04, 0.95).dx, p(0.04, 0.95).dy);
        path.lineTo(p(0.96, 0.95).dx, p(0.96, 0.95).dy);
      default: // luna
        final outer = Path()..addOval(Rect.fromLTWH(r.left, r.top, r.width, r.height));
        final inner = Path()
          ..addOval(Rect.fromLTWH(
            r.left + r.width * 0.3,
            r.top - r.height * 0.06,
            r.width * 0.86,
            r.height * 0.9,
          ));
        path.addPath(Path.combine(PathOperation.difference, outer, inner), Offset.zero);
        for (final s in [
          [0.74, 0.22],
          [0.9, 0.52],
          [0.68, 0.78],
        ]) {
          final o = p(s[0], s[1]);
          final d = r.height * 0.05;
          path.moveTo(o.dx - d, o.dy);
          path.lineTo(o.dx + d, o.dy);
          path.moveTo(o.dx, o.dy - d);
          path.lineTo(o.dx, o.dy + d);
        }
    }
    return path;
  }

  void _neonStroke(
    Canvas canvas,
    Path path,
    double s,
    double alpha,
    double glow,
  ) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 9 * s
        ..color = color.withValues(alpha: 0.4 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow * s),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4.5 * s
        ..color = color.withValues(alpha: 0.75 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow * 0.4 * s),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2 * s
        ..color = Color.lerp(color, Colors.white, 0.8)!.withValues(alpha: alpha),
    );
  }

  void _neon(Canvas canvas, Size size) {
    final h = size.height;
    final s = h / 200;
    final side = h * 0.62;
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.74, h * 0.5),
      width: side,
      height: side,
    );
    final broken = rarity == Rarity.epico;
    final key = design.replaceAll('_rota', '');
    final path = _shape(key, rect);

    if (!broken) {
      final wave = 0.5 + 0.5 * math.sin(_twoPi * t);
      _neonStroke(canvas, path, s, 0.85 + 0.15 * wave, 7 + 3 * wave);
      return;
    }

    // Neón roto: el tubo está partido en tramos; unos no encienden, otros
    // parpadean y los demás brillan tenues.
    var contour = 0;
    for (final metric in path.computeMetrics()) {
      final segment = 26 * s;
      final count = math.max(1, (metric.length / segment).ceil());
      for (var i = 0; i < count; i++) {
        final from = i * segment;
        final to = math.min(metric.length, (i + 1) * segment);
        final part = metric.extractPath(from, to);
        final id = contour * 31 + i;
        final seed = ((id * 2654435761) & 0xFFFF) / 65535.0;
        if (seed < 0.28) {
          // Tramo apagado: solo se alcanza a ver el tubo.
          canvas.drawPath(
            part,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = 2 * s
              ..color = color.withValues(alpha: 0.14),
          );
          continue;
        }
        final speed = 2 + id % 3;
        final phase = (t * speed + seed) % 1.0;
        final on = phase < 0.78;
        final alpha = on ? 0.5 + 0.3 * seed : 0.07;
        _neonStroke(canvas, part, s, alpha, 5);
      }
      contour++;
    }
  }

  @override
  bool shouldRepaint(covariant GrafitiPainter old) =>
      old.t != t ||
      old.design != design ||
      old.color != color ||
      old.rarity != rarity;
}
