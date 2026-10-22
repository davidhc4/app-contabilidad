import 'package:flutter/services.dart';

/// "100000" -> "100.000". Quita ceros a la izquierda.
String formatThousands(String digits) {
  var d = digits.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return '';
  d = d.replaceFirst(RegExp(r'^0+'), '');
  if (d.isEmpty) return '0';
  final buffer = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) buffer.write('.');
    buffer.write(d[i]);
  }
  return buffer.toString();
}

/// "100.000" -> 100000. Devuelve null si no hay números.
int? parseThousands(String text) {
  final d = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return null;
  return int.tryParse(d);
}

/// Mientras el usuario escribe, pone el punto de los miles solo: al
/// escribir 100000 se ve 100.000. Solo admite números enteros.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  static const _maxDigits = 13;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final formatted = formatThousands(digits);

    // Mantiene el cursor junto al mismo dígito donde estaba.
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = newValue.text
        .substring(0, end)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBeforeCursor) {
      if (formatted[offset] != '.') seen++;
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
