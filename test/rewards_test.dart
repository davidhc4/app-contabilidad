import 'dart:math' as math;

import 'package:app_contabilidad/features/rewards/rewards_state.dart';
import 'package:app_contabilidad/features/rewards/skins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cajas', () {
    test('la primera llega a los 5 minutos', () {
      expect(boxProgress(0).earned, 0);
      expect(boxProgress(299).earned, 0);
      expect(boxProgress(300).earned, 1);
    });

    test('los tramos son 5, 10, 20, 40, 80 y luego 100 minutos', () {
      expect([for (var n = 0; n < 8; n++) boxIntervalMinutes(n)],
          [5, 10, 20, 40, 80, 100, 100, 100]);
      // 5 + 10 + 20 = 35 minutos para tener 3 cajas.
      expect(boxProgress(35 * 60).earned, 3);
      expect(boxProgress(35 * 60 - 1).earned, 2);
    });

    test('muestra el avance hacia la siguiente caja', () {
      final p = boxProgress(5 * 60 + 150);
      expect(p.earned, 1);
      expect(p.into, 150);
      expect(p.interval, 600);
      expect(p.remaining, 450);
    });
  });

  group('aspectos', () {
    test('los ids son únicos y se pueden buscar', () {
      final ids = {for (final s in [...kSkins, ...kExtraSkins]) s.id};
      expect(ids.length, kSkins.length + kExtraSkins.length);
      for (final s in kSkins) {
        expect(skinById(s.id), same(s));
      }
    });

    test('el sorteo solo da aspectos de cajas', () {
      final rng = math.Random(1);
      for (var i = 0; i < 300; i++) {
        final s = pickSkin(rng);
        expect(s.special, isFalse);
        expect(kSkins.contains(s), isTrue);
      }
    });

    test('hay aspectos de todas las rarezas de las cajas', () {
      for (final r in Rarity.values.where((r) => r.weight > 0)) {
        expect(kSkins.any((s) => s.rarity == r), isTrue, reason: r.label);
      }
    });
  });
}
