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

class _Sleigh extends StatelessWidget {
  final double width;
  const _Sleigh({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 60,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 8,
            child: Text('🦌🦌', style: TextStyle(fontSize: 34)),
          ),
          const Positioned(
            left: 72,
            top: 8,
            child: Text('🛷', style: TextStyle(fontSize: 38)),
          ),
          const Positioned(
            left: 84,
            top: -4,
            child: Text('🎅', style: TextStyle(fontSize: 26)),
          ),
          Positioned(
            left: 118,
            top: 14,
            child: Text(
              '✨✨✨',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
