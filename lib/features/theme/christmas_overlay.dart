import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rewards/rewards_state.dart';
import 'navidad.dart';
import 'xmas_paint.dart';

/// Decoración del tema de Navidad que va encima de la app: nieve cayendo,
/// luces que titilan arriba, acebo en las esquinas, siluetas navideñas muy
/// tenues de fondo y un trineo que cruza el cielo de vez en cuando (se puede
/// tocar). Aparece y desaparece con un desvanecimiento.
class ChristmasFx extends ConsumerStatefulWidget {
  const ChristmasFx({super.key});

  @override
  ConsumerState<ChristmasFx> createState() => _ChristmasFxState();
}

class _ChristmasFxState extends ConsumerState<ChristmasFx>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  late final AnimationController _sleigh = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  );
  final _rng = math.Random();
  Timer? _timer;
  Timer? _hide;
  bool _shown = false;
  bool _visible = false;
  double _lane = 0.16;

  @override
  void initState() {
    super.initState();
    _scheduleSleigh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hide?.cancel();
    _loop.dispose();
    _sleigh.dispose();
    super.dispose();
  }

  void _scheduleSleigh() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 15 + _rng.nextInt(25)), () {
      if (!mounted) return;
      if (ref.read(navidadProvider) && !_sleigh.isAnimating) {
        setState(() => _lane = 0.12 + _rng.nextDouble() * 0.12);
        _sleigh.forward(from: 0).whenComplete(() {
          if (mounted) _scheduleSleigh();
        });
      } else {
        _scheduleSleigh();
      }
    });
  }

  Future<void> _poke() async {
    HapticFeedback.selectionClick();
    final id = await sleighTick();
    if (id == null || !mounted) return;
    await ref.read(rewardsProvider.notifier).grant(id);
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(navidadProvider);
    if (active) {
      _hide?.cancel();
      _shown = true;
      if (!_loop.isAnimating) _loop.repeat();
      if (!_visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ref.read(navidadProvider)) {
            setState(() => _visible = true);
          }
        });
      }
    } else if (_shown && !(_hide?.isActive ?? false)) {
      _visible = false;
      _hide = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _loop.stop();
        setState(() => _shown = false);
      });
    }
    if (!_shown) return const SizedBox.shrink();

    final top = MediaQuery.of(context).padding.top;
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _XmasSilhouettesPainter()),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => CustomPaint(
                  painter: _XmasPainter(_loop.value, top),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, c) => AnimatedBuilder(
                animation: _sleigh,
                builder: (context, _) {
                  if (!_sleigh.isAnimating) return const SizedBox.shrink();
                  final v = _sleigh.value;
                  const width = 170.0;
                  // Va de derecha a izquierda, con un vaivén suave.
                  final x = c.maxWidth + 20 - v * (c.maxWidth + width + 40);
                  final y = c.maxHeight * _lane + math.sin(v * math.pi * 4) * 14;
                  // El trineo debe ir dentro de un Stack para poder colocarlo
                  // con Positioned sin romper el dibujado.
                  return Stack(
                    children: [
                      Positioned(
                        left: x,
                        top: y,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _poke,
                          child: const _Sleigh(width: width),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trineo de Papá Noel tirado por dos renos, dibujado a mano para que se vea
/// igual en cualquier celular (sin depender de los emojis del sistema). Mira
/// hacia la izquierda, que es hacia donde se mueve.
class _Sleigh extends StatelessWidget {
  final double width;
  const _Sleigh({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.35,
      child: CustomPaint(painter: _SleighPainter()),
    );
  }
}

class _SleighPainter extends CustomPainter {
  static const _brown = Color(0xFF9A6A3A);
  static const _darkBrown = Color(0xFF6E4A28);
  static const _red = Color(0xFFD12B38);
  static const _gold = Color(0xFFF2C14E);
  static const _white = Color(0xFFF5F5F5);
  static const _peach = Color(0xFFF2C9A0);
  static const _belt = Color(0xFF3C281E);
  static const _rein = Color(0xFF7A5230);
  static const _spark = Color(0xFFFFF3B0);

  Paint _fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  void _oval(Canvas c, double cx, double cy, double rx, double ry, Color color) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2), _fill(color));
  }

  void _poly(Canvas c, List<Offset> pts, Color color) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    c.drawPath(path, _fill(color));
  }

  void _reindeer(Canvas c, double cx) {
    final leg = _stroke(_darkBrown, 3);
    for (final dx in const [[-6.0, -8.0], [-1.0, -1.0], [6.0, 8.0], [11.0, 12.0]]) {
      c.drawLine(Offset(cx + dx[0], 40), Offset(cx + dx[1], 56), leg);
    }
    _oval(c, cx, 34, 15, 8, _brown);
    _oval(c, cx + 9, 31, 9, 8, _brown);
    _poly(c, [Offset(cx + 14, 28), Offset(cx + 18, 26), Offset(cx + 15, 33)], _brown);
    _poly(c, [Offset(cx - 10, 30), Offset(cx - 4, 30), Offset(cx - 14, 18), Offset(cx - 18, 20)], _brown);
    _oval(c, cx - 17, 19, 5, 4, _brown);
    _oval(c, cx - 22, 21, 3, 2.5, _darkBrown);
    final antler = _stroke(_darkBrown, 2);
    c.drawLine(Offset(cx - 17, 15), Offset(cx - 19, 7), antler);
    c.drawLine(Offset(cx - 19, 10), Offset(cx - 23, 8), antler);
    c.drawLine(Offset(cx - 19, 8), Offset(cx - 16, 5), antler);
    c.drawLine(Offset(cx - 14, 15), Offset(cx - 12, 7), antler);
    c.drawLine(Offset(cx - 13, 10), Offset(cx - 9, 9), antler);
  }

  void _star4(Canvas c, double cx, double cy, double r, double alpha) {
    final p = _stroke(_spark.withValues(alpha: alpha), 1.4);
    c.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), p);
    c.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200;
    canvas.save();
    canvas.scale(s);

    _reindeer(canvas, 34);
    _reindeer(canvas, 76);

    final rein = _stroke(_rein, 1.6);
    canvas.drawLine(const Offset(104, 36), const Offset(50, 24), rein);
    canvas.drawLine(const Offset(104, 38), const Offset(90, 26), rein);

    // Patín dorado.
    final runner = Path()
      ..moveTo(97, 50)
      ..lineTo(106, 58)
      ..lineTo(166, 58)
      ..lineTo(173, 50);
    canvas.drawPath(runner, _stroke(_gold, 4));
    canvas.drawCircle(const Offset(97, 50), 3, _stroke(_gold, 2));
    canvas.drawCircle(const Offset(173, 50), 3, _stroke(_gold, 2));

    // Cuerpo del trineo y proa.
    _poly(canvas, const [
      Offset(106, 54), Offset(166, 54), Offset(166, 28),
      Offset(156, 28), Offset(156, 40), Offset(106, 40),
    ], _red);
    _poly(canvas, const [
      Offset(106, 40), Offset(99, 38), Offset(96, 30),
      Offset(99, 25), Offset(104, 27), Offset(106, 33),
    ], _red);

    // Papá Noel.
    _oval(canvas, 140, 33, 9, 10, _red);
    canvas.drawLine(const Offset(131, 33), const Offset(149, 33), _stroke(_belt, 2));
    canvas.drawLine(const Offset(131, 30), const Offset(126, 22), _stroke(_red, 4));
    _oval(canvas, 132, 24, 5, 5, _peach);
    _poly(canvas, const [
      Offset(127, 24), Offset(137, 24), Offset(134, 32),
      Offset(132, 33), Offset(130, 32),
    ], _white);
    _poly(canvas, const [Offset(127, 20), Offset(137, 19), Offset(130, 8)], _red);
    canvas.drawRect(const Rect.fromLTRB(126, 18, 138, 21), _fill(_white));
    canvas.drawCircle(const Offset(129, 8), 2.5, _fill(_white));

    // Estela de destellos.
    _star4(canvas, 178, 30, 5, 0.95);
    _star4(canvas, 188, 24, 4, 0.75);
    _star4(canvas, 185, 40, 3, 0.55);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SleighPainter oldDelegate) => false;
}

class _XmasPainter extends CustomPainter {
  final double t;
  final double top;
  _XmasPainter(this.t, this.top);

  @override
  void paint(Canvas canvas, Size size) {
    paintSnow(canvas, size, t);
    paintLights(canvas, size.width, top + 2, t);
    paintHolly(canvas, Offset(size.width - 6, size.height - 96), 0.9, math.pi * 1.05);
    paintHolly(canvas, const Offset(6, 4), 0.8, math.pi * 0.08);
  }

  @override
  bool shouldRepaint(covariant _XmasPainter old) => old.t != t || old.top != top;
}

/// Siluetas navideñas muy tenues repartidas por el fondo.
class _XmasSilhouettesPainter extends CustomPainter {
  const _XmasSilhouettesPainter();

  static final _ink = const Color(0xFFBFE8CF).withValues(alpha: 0.06);

  void _tree(Canvas c, double s, Paint fill) {
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final y = -s * 0.5 + i * s * 0.28;
      final w = s * (0.34 + 0.16 * i);
      path
        ..moveTo(0, y - s * 0.12)
        ..lineTo(w, y + s * 0.3)
        ..lineTo(-w, y + s * 0.3)
        ..close();
    }
    path.addRect(Rect.fromLTWH(-s * 0.06, s * 0.32, s * 0.12, s * 0.16));
    c.drawPath(path, fill);
  }

  void _gift(Canvas c, double s, Paint fill) {
    final body = Path()..addRect(Rect.fromCenter(center: Offset.zero, width: s * 0.8, height: s * 0.6));
    final ribbon = Path()
      ..addRect(Rect.fromCenter(center: Offset.zero, width: s * 0.12, height: s * 0.6))
      ..addRect(Rect.fromCenter(center: Offset.zero, width: s * 0.8, height: s * 0.12));
    c.drawPath(Path.combine(PathOperation.difference, body, ribbon), fill);
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.14, -s * 0.38), width: s * 0.26, height: s * 0.18), fill);
    c.drawOval(Rect.fromCenter(center: Offset(s * 0.14, -s * 0.38), width: s * 0.26, height: s * 0.18), fill);
  }

  void _snowman(Canvas c, double s, Paint fill) {
    c.drawCircle(Offset(0, s * 0.28), s * 0.26, fill);
    c.drawCircle(Offset(0, -s * 0.06), s * 0.19, fill);
    c.drawCircle(Offset(0, -s * 0.3), s * 0.13, fill);
    c.drawRect(Rect.fromCenter(center: Offset(0, -s * 0.46), width: s * 0.24, height: s * 0.12), fill);
  }

  void _bell(Canvas c, double s, Paint fill) {
    final path = Path()
      ..moveTo(-s * 0.36, s * 0.22)
      ..quadraticBezierTo(-s * 0.3, -s * 0.4, 0, -s * 0.4)
      ..quadraticBezierTo(s * 0.3, -s * 0.4, s * 0.36, s * 0.22)
      ..lineTo(s * 0.46, s * 0.3)
      ..lineTo(-s * 0.46, s * 0.3)
      ..close();
    c.drawPath(path, fill);
    c.drawCircle(Offset(0, s * 0.4), s * 0.08, fill);
  }

  void _flake(Canvas c, double s, Paint stroke) {
    for (var i = 0; i < 6; i++) {
      c.save();
      c.rotate(i * math.pi / 3);
      c.drawLine(Offset.zero, Offset(0, -s * 0.5), stroke);
      c.drawLine(Offset(0, -s * 0.3), Offset(s * 0.12, -s * 0.42), stroke);
      c.drawLine(Offset(0, -s * 0.3), Offset(-s * 0.12, -s * 0.42), stroke);
      c.restore();
    }
  }

  void _cane(Canvas c, double s, Paint stroke) {
    final path = Path()
      ..moveTo(-s * 0.1, s * 0.5)
      ..lineTo(-s * 0.1, -s * 0.2)
      ..arcToPoint(Offset(s * 0.26, -s * 0.2),
          radius: Radius.circular(s * 0.18), clockwise: true);
    c.drawPath(path, stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(17);
    final fill = Paint()..color = _ink;
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const rowHeight = 118.0;
    const colWidth = 104.0;
    var index = 0;
    for (var row = 0; row * rowHeight < size.height + rowHeight; row++) {
      final shift = row.isOdd ? colWidth / 2 : 0.0;
      for (var col = -1; col * colWidth < size.width + colWidth; col++) {
        final kind = (index++ + row) % 7;
        final s = 54.0 * (0.7 + rng.nextDouble() * 0.4);
        canvas.save();
        canvas.translate(
          col * colWidth + shift + rng.nextDouble() * 22,
          row * rowHeight + rng.nextDouble() * 22,
        );
        canvas.rotate((rng.nextDouble() - 0.5) * 0.6);
        switch (kind) {
          case 0:
            _tree(canvas, s, fill);
          case 1:
            _flake(canvas, s, stroke);
          case 2:
            _gift(canvas, s, fill);
          case 3:
            canvas.drawPath(starPath(Offset.zero, s * 0.5), fill);
          case 4:
            _snowman(canvas, s, fill);
          case 5:
            _bell(canvas, s, fill);
          default:
            _cane(canvas, s, stroke);
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _XmasSilhouettesPainter oldDelegate) => false;
}
