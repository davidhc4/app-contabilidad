import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rewards/rewards_state.dart';
import 'fx_state.dart';
import 'halloween.dart';
import 'silhouettes.dart';

/// Capa que va encima de toda la app: telarañas con arañas que pasean
/// (solo con el tema de Halloween) y murciélagos al cambiar de tema.
class ThemeFxLayer extends ConsumerStatefulWidget {
  final Widget child;
  const ThemeFxLayer({super.key, required this.child});

  @override
  ConsumerState<ThemeFxLayer> createState() => _ThemeFxLayerState();
}

class _ThemeFxLayerState extends ConsumerState<ThemeFxLayer>
    with TickerProviderStateMixin {
  late final AnimationController _bats = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _spiders = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  final _rng = math.Random();
  Timer? _timer;
  int _scenario = 0;
  bool _topRight = true;
  bool _batsUp = true;

  @override
  void initState() {
    super.initState();
    _scheduleSpiders();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bats.dispose();
    _spiders.dispose();
    super.dispose();
  }

  void _scheduleSpiders() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 6 + _rng.nextInt(12)), () {
      if (!mounted) return;
      if (ref.read(halloweenProvider) && !_spiders.isAnimating) {
        setState(() {
          _scenario = _rng.nextInt(4);
          _topRight = _rng.nextBool();
        });
        _spiders.forward(from: 0).whenComplete(() {
          if (mounted) _scheduleSpiders();
        });
      } else {
        _scheduleSpiders();
      }
    });
  }

  Future<void> _poke() async {
    HapticFeedback.selectionClick();
    final id = await fxTick();
    if (id == null || !mounted) return;
    // El aviso de "aspecto nuevo" sale solo desde las recompensas.
    await ref.read(rewardsProvider.notifier).grant(id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ThemeSwitchEvent?>(themeSwitchEventProvider, (previous, next) {
      if (next == null) return;
      setState(() => _batsUp = next.toHalloween);
      _bats.forward(from: 0);
    });
    final halloween = ref.watch(halloweenProvider);

    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (halloween) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _SilhouettesPainter()),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _WebPainter(topRight: true)),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _WebPainter(topRight: false)),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final size = Size(c.maxWidth, c.maxHeight);
                return AnimatedBuilder(
                  animation: _spiders,
                  builder: (context, _) {
                    if (!_spiders.isAnimating) return const SizedBox.shrink();
                    final painter = _SpiderPainter(
                      t: _spiders.value,
                      scenario: _scenario,
                      topRight: _topRight,
                    );
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: painter),
                          ),
                        ),
                        for (final pose in painter.poses(size))
                          Positioned(
                            left: pose.pos.dx - 24,
                            top: pose.pos.dy - 24,
                            width: 48,
                            height: 48,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _poke,
                              child: const SizedBox.expand(),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _bats,
              builder: (context, _) {
                if (!_bats.isAnimating) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _BatsPainter(t: _bats.value, up: _batsUp),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Fondo del tema: siluetas apagadas de calaveras, murciélagos, zombis y
/// vampiros repartidas por toda la pantalla (muy tenues para no estorbar).
class _SilhouettesPainter extends CustomPainter {
  static const _shapes = [kSkull, kBat, kZombie, kVampire, kBat, kZombie];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(31);
    final paint = Paint()..color = const Color(0xFFBDB0D8).withValues(alpha: 0.06);
    const rowHeight = 118.0;
    const colWidth = 104.0;
    var index = 0;
    for (var row = 0; row * rowHeight < size.height + rowHeight; row++) {
      final shift = row.isOdd ? colWidth / 2 : 0.0;
      for (var col = -1; col * colWidth < size.width + colWidth; col++) {
        final shape = _shapes[(index++ + row) % _shapes.length];
        final scale = 0.62 + rng.nextDouble() * 0.38;
        final box = (shape == kBat ? 52.0 : 62.0) * scale;
        final center = Offset(
          col * colWidth + shift + rng.nextDouble() * 22,
          row * rowHeight + rng.nextDouble() * 22,
        );
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate((rng.nextDouble() - 0.5) * 0.7);
        canvas.drawPath(
          shape.path(Rect.fromCenter(center: Offset.zero, width: box, height: box)),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettesPainter oldDelegate) => false;
}

/// Geometría de una telaraña en una esquina: el centro, el arco por el que
/// caminan las arañas y su radio.
class _WebGeo {
  final Offset center;
  final double a0;
  final double a1;
  final double r;
  const _WebGeo(this.center, this.a0, this.a1, this.r);

  factory _WebGeo.of(Size size, bool topRight) {
    return topRight
        ? _WebGeo(Offset(size.width, 0), math.pi * 1.14, math.pi * 0.40, 105)
        : _WebGeo(Offset(0, size.height), math.pi * 0.10, -math.pi * 0.60, 105);
  }

  Offset at(double s, double off) {
    final a = a0 + (a1 - a0) * s;
    final rr = r + off;
    return center + Offset(math.cos(a) * rr, math.sin(a) * rr);
  }
}

class _WebPainter extends CustomPainter {
  final bool topRight;
  _WebPainter({required this.topRight});

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _WebGeo.of(size, topRight);
    final start = topRight ? math.pi : 0.0;
    final end = topRight ? math.pi / 2 : -math.pi / 2;
    const spokes = 6;
    const radii = [34.0, 68.0, 105.0, 138.0, 170.0];
    final paint = Paint()
      ..color = const Color(0xFFE9E1F5).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    Offset point(int i, double radius) {
      final a = start + (end - start) * i / (spokes - 1);
      return geo.center + Offset(math.cos(a) * radius, math.sin(a) * radius);
    }

    for (var i = 0; i < spokes; i++) {
      canvas.drawLine(geo.center, point(i, radii.last), paint);
    }
    for (final radius in radii) {
      final path = Path()..moveTo(point(0, radius).dx, point(0, radius).dy);
      for (var i = 0; i < spokes - 1; i++) {
        final p1 = point(i, radius);
        final p2 = point(i + 1, radius);
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final control = mid + (geo.center - mid) * 0.14;
        path.quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WebPainter oldDelegate) => false;
}

enum _Mood { walking, stuck, sitting }

class _Pose {
  final Offset pos;
  final double heading;
  final _Mood mood;
  const _Pose(this.pos, this.heading, this.mood);
}

class _SpiderPainter extends CustomPainter {
  final double t;
  final int scenario;
  final bool topRight;
  _SpiderPainter({
    required this.t,
    required this.scenario,
    required this.topRight,
  });

  static double _ease(double x) => Curves.easeInOut.transform(x.clamp(0.0, 1.0));

  _Pose _pose(_WebGeo g, double s, double off, int dir, _Mood mood) {
    final p1 = g.at(s, off);
    final p2 = g.at(s + dir * 0.01, off);
    return _Pose(p1, math.atan2(p2.dy - p1.dy, p2.dx - p1.dx), mood);
  }

  List<_Pose> poses(Size size) => _poses(_WebGeo.of(size, topRight));

  List<_Pose> _poses(_WebGeo g) {
    switch (scenario) {
      case 1: // se le atora una pata en la telaraña
        if (t < 0.4) {
          return [_pose(g, 0.5 * _ease(t / 0.4), 0, 1, _Mood.walking)];
        }
        if (t < 0.65) return [_pose(g, 0.5, 0, 1, _Mood.stuck)];
        return [
          _pose(g, 0.5 + 0.5 * _ease((t - 0.65) / 0.35), 0, 1, _Mood.walking),
        ];
      case 2: // dos arañas se cruzan
        return [
          _pose(g, _ease(t), -9, 1, _Mood.walking),
          _pose(g, 1 - _ease(t), 9, -1, _Mood.walking),
        ];
      case 3: // chocan, rebotan, se sientan y se van
        double a() {
          if (t < 0.35) return 0.44 * _ease(t / 0.35);
          if (t < 0.45) return 0.44 - 0.12 * _ease((t - 0.35) / 0.1);
          if (t < 0.7) return 0.32;
          return 0.32 + 0.68 * _ease((t - 0.7) / 0.3);
        }
        final mood = (t >= 0.45 && t < 0.7) ? _Mood.sitting : _Mood.walking;
        return [
          _pose(g, a(), -6, 1, mood),
          _pose(g, 1 - a(), 6, -1, mood),
        ];
      default: // una araña cruza tranquila
        return [_pose(g, _ease(t), 0, 1, _Mood.walking)];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _WebGeo.of(size, topRight);
    for (final pose in _poses(geo)) {
      _drawSpider(canvas, pose);
    }
  }

  void _drawSpider(Canvas canvas, _Pose pose) {
    canvas.save();
    canvas.translate(pose.pos.dx, pose.pos.dy);
    canvas.rotate(pose.heading);
    final jitter = pose.mood == _Mood.stuck ? math.sin(t * 160) * 0.8 : 0.0;
    canvas.translate(0, jitter);

    final legPaint = Paint()
      ..color = const Color(0xFFB07CD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final phase = t * 70;

    for (var side = -1; side <= 1; side += 2) {
      for (var i = 0; i < 4; i++) {
        final baseX = 4.0 - i * 2.4;
        var swing = math.sin(phase + i * 1.4 + (side > 0 ? math.pi : 0)) * 3;
        var reach = 12.0;
        var knee = 7.0;
        if (pose.mood == _Mood.sitting) {
          swing = 0;
          reach = 7;
          knee = 5;
        }
        if (pose.mood == _Mood.stuck && side > 0 && i == 0) {
          swing = math.sin(t * 150) * 5;
          reach = 17;
        }
        final path = Path()
          ..moveTo(baseX, 0)
          ..lineTo(baseX + swing * 0.4 + (i - 1.5) * 1.2, side * knee)
          ..lineTo(baseX + swing + (i - 1.5) * 3.2, side * reach);
        canvas.drawPath(path, legPaint);
      }
    }

    final body = Paint()..color = const Color(0xFF3A2150);
    final outline = Paint()
      ..color = const Color(0xFF8E5BB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(const Offset(-4, 0), 6.5, body);
    canvas.drawCircle(const Offset(-4, 0), 6.5, outline);
    canvas.drawCircle(const Offset(4, 0), 3.8, body);
    canvas.drawCircle(const Offset(4, 0), 3.8, outline);
    final eye = Paint()..color = const Color(0xFFFF4D4D);
    canvas.drawCircle(const Offset(5.4, -1.5), 0.9, eye);
    canvas.drawCircle(const Offset(5.4, 1.5), 0.9, eye);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpiderPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.scenario != scenario ||
      oldDelegate.topRight != topRight;
}

class _BatSeed {
  final double x;
  final double delay;
  final double size;
  final double phase;
  const _BatSeed(this.x, this.delay, this.size, this.phase);
}

final List<_BatSeed> _batSeeds = () {
  final rng = math.Random(13);
  return List<_BatSeed>.generate(
    18,
    (_) => _BatSeed(
      0.05 + rng.nextDouble() * 0.9,
      rng.nextDouble() * 0.35,
      9 + rng.nextDouble() * 12,
      rng.nextDouble() * math.pi * 2,
    ),
  );
}();

/// Murciélagos que cruzan la pantalla: de abajo hacia arriba al activar
/// Halloween y de arriba hacia abajo al volver al tema normal.
class _BatsPainter extends CustomPainter {
  final double t;
  final bool up;
  _BatsPainter({required this.t, required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFF2B1840);
    final edge = Paint()
      ..color = const Color(0xFFFF7A18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final b in _batSeeds) {
      final p = ((t - b.delay) / (1 - 0.35)).clamp(0.0, 1.0);
      final y = up
          ? size.height * (1.1 - p * 1.3)
          : size.height * (-0.1 + p * 1.3);
      final x = b.x * size.width + math.sin(p * 9 + b.phase) * 28;
      final flap = 0.5 + 0.5 * math.sin(t * 38 + b.phase);
      canvas.save();
      canvas.translate(x, y);
      if (!up) canvas.scale(1, -1);
      _bat(canvas, b.size, flap, fill, edge);
      canvas.restore();
    }
  }

  void _bat(Canvas canvas, double u, double flap, Paint fill, Paint edge) {
    final f = 0.3 + 0.7 * flap;
    for (var m = 0; m < 2; m++) {
      canvas.save();
      if (m == 1) canvas.scale(-1, 1);
      final wing = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-0.9 * u, -1.1 * u * f, -1.8 * u, -0.3 * u * f + 0.2 * u)
        ..quadraticBezierTo(-1.4 * u, 0.2 * u, -1.1 * u, 0.4 * u)
        ..quadraticBezierTo(-0.8 * u, 0.15 * u, -0.5 * u, 0.55 * u)
        ..quadraticBezierTo(-0.25 * u, 0.25 * u, 0, 0.5 * u)
        ..close();
      canvas.drawPath(wing, fill);
      canvas.drawPath(wing, edge);
      canvas.restore();
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 0.6 * u, height: 1.1 * u),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BatsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.up != up;
}
