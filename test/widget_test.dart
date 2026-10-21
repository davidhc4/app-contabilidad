import 'package:flutter_test/flutter_test.dart';
import 'package:app_contabilidad/features/sms_detection/sms_parser.dart';

void main() {
  group('SmsParser.parse', () {
    test('extrae monto con puntos como separador de miles', () {
      final result = SmsParser.parse(
        'Realizaste una compra por \$45.000 en EXITO el 10/10',
      );
      expect(result, isNotNull);
      expect(result!.amount, 45000);
      expect(result.merchant, 'EXITO');
    });

    test('extrae monto con comas como separador de miles y centavos', () {
      final result = SmsParser.parse(
        'Pago aprobado por COP 1,250.50 en NETFLIX',
      );
      expect(result, isNotNull);
      expect(result!.amount, closeTo(1250.50, 0.001));
    });

    test('ignora SMS que no parecen de pago', () {
      final result = SmsParser.parse(
        'Tu código de verificación es 453211, no lo compartas',
      );
      expect(result, isNull);
    });

    test('usa un regex personalizado cuando se provee', () {
      final result = SmsParser.parse(
        'TXN: monto=12500 ref=998',
        customRegex: r'monto=([0-9]+)',
      );
      expect(result, isNotNull);
      expect(result!.amount, 12500);
    });

    test('rechaza montos no numéricos o cero', () {
      final result = SmsParser.parse('Compra por \$0 en TEST');
      expect(result, isNull);
    });
  });
}
