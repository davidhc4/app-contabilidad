// Siluetas dibujadas a mano (formas simples en un cuadro de 0 a 1) para el
// fondo del tema de Halloween y para el aspecto del murciélago.
//
// Cada figura es una lista de piezas: [0, x1, y1, x2, y2, ...] es un polígono
// y [1, cx, cy, rx, ry] es un óvalo. Los "huecos" se recortan de la figura.
import 'dart:ui';

class Silhouette {
  final List<List<double>> body;
  final List<List<double>> holes;
  const Silhouette(this.body, this.holes);

  Path _build(List<List<double>> parts, Rect r) {
    final path = Path();
    for (final p in parts) {
      if (p[0] == 0) {
        for (var i = 1; i + 1 < p.length; i += 2) {
          final o = Offset(r.left + p[i] * r.width, r.top + p[i + 1] * r.height);
          i == 1 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        path.close();
      } else {
        path.addOval(Rect.fromCenter(
          center: Offset(r.left + p[1] * r.width, r.top + p[2] * r.height),
          width: p[3] * 2 * r.width,
          height: p[4] * 2 * r.height,
        ));
      }
    }
    return path;
  }

  /// Contorno de la figura dentro del rectángulo [r].
  Path path(Rect r) {
    final body = _build(this.body, r);
    if (holes.isEmpty) return body;
    return Path.combine(PathOperation.difference, body, _build(holes, r));
  }
}

const kBat = Silhouette(
  [
    [0, 0.500, 0.300, 0.540, 0.170, 0.580, 0.300, 0.660, 0.300, 0.760, 0.220, 0.880, 0.240, 0.990, 0.380, 0.930, 0.400, 0.880, 0.520, 0.800, 0.460, 0.740, 0.600, 0.640, 0.500, 0.580, 0.620, 0.540, 0.800, 0.500, 0.740, 0.500, 0.740, 0.460, 0.800, 0.420, 0.620, 0.360, 0.500, 0.260, 0.600, 0.200, 0.460, 0.120, 0.520, 0.070, 0.400, 0.010, 0.380, 0.120, 0.240, 0.240, 0.220, 0.340, 0.300, 0.420, 0.300, 0.460, 0.170, 0.500, 0.300],
  ],
  [],
);

const kSkull = Silhouette(
  [
    [1, 0.500, 0.400, 0.340, 0.360],
    [0, 0.260, 0.620, 0.740, 0.620, 0.680, 0.950, 0.320, 0.950],
  ],
  [
    [1, 0.360, 0.420, 0.090, 0.100],
    [1, 0.640, 0.420, 0.090, 0.100],
    [0, 0.500, 0.520, 0.450, 0.640, 0.550, 0.640],
    [0, 0.380, 0.780, 0.400, 0.950, 0.430, 0.950, 0.430, 0.780],
    [0, 0.480, 0.780, 0.480, 0.950, 0.520, 0.950, 0.520, 0.780],
    [0, 0.570, 0.780, 0.570, 0.950, 0.600, 0.950, 0.620, 0.780],
  ],
);

const kZombie = Silhouette(
  [
    [1, 0.500, 0.100, 0.090, 0.090],
    [0, 0.430, 0.180, 0.570, 0.180, 0.600, 0.550, 0.400, 0.550],
    [0, 0.560, 0.220, 0.970, 0.280, 0.970, 0.340, 0.580, 0.340],
    [0, 0.550, 0.300, 0.900, 0.400, 0.900, 0.460, 0.560, 0.410],
    [0, 0.410, 0.550, 0.500, 0.550, 0.440, 1.000, 0.340, 1.000],
    [0, 0.500, 0.550, 0.600, 0.550, 0.720, 0.980, 0.620, 1.000],
    [0, 0.380, 0.220, 0.440, 0.220, 0.420, 0.600, 0.360, 0.600],
  ],
  [],
);

const kVampire = Silhouette(
  [
    [1, 0.500, 0.300, 0.170, 0.210],
    [0, 0.320, 0.220, 0.400, 0.040, 0.500, 0.100, 0.600, 0.040, 0.680, 0.220, 0.600, 0.160, 0.500, 0.200, 0.400, 0.160],
    [0, 0.140, 0.160, 0.400, 0.580, 0.160, 0.620],
    [0, 0.860, 0.160, 0.600, 0.580, 0.840, 0.620],
    [0, 0.180, 0.560, 0.820, 0.560, 0.980, 1.000, 0.020, 1.000],
  ],
  [
    [0, 0.500, 0.600, 0.400, 0.600, 0.500, 0.980, 0.600, 0.600],
    [1, 0.430, 0.300, 0.035, 0.022],
    [1, 0.570, 0.300, 0.035, 0.022],
    [0, 0.450, 0.410, 0.490, 0.410, 0.470, 0.470],
    [0, 0.510, 0.410, 0.550, 0.410, 0.530, 0.470],
  ],
);
