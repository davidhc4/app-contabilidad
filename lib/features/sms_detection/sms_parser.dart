/// Resultado de intentar extraer los datos de un pago desde un SMS.
class ParsedPayment {
  final double amount;
  final String? merchant;
  final DateTime date;

  ParsedPayment({required this.amount, this.merchant, required this.date});
}

/// Palabras que suelen aparecer en SMS de notificación de pago/compra con
/// tarjeta. Se usa como filtro genérico cuando el remitente no tiene un
/// patrón configurado, para no disparar el flujo con cualquier SMS.
const _paymentKeywords = [
  'compra',
  'pago',
  'pagaste',
  'transaccion',
  'transacción',
  'tarjeta',
  'débito',
  'debito',
  'crédito',
  'credito',
  'retiro',
];

/// Patrón genérico de monto: soporta formatos como
/// "$45.000", "COP 45,000.00", "USD 12.50", "45000".
final _amountRegex = RegExp(
  r'(?:USD|COP|S/|\$)?\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})?)',
);

/// Intenta extraer un posible comercio: lo que sigue a "en" hasta el
/// siguiente signo de puntuación fuerte.
final _merchantRegex = RegExp(
  r'\ben\s+([A-ZÁÉÍÓÚÑ][\w\s.&-]{2,30}?)(?:[.,]|\s+el\s|\s+por\s|$)',
  caseSensitive: false,
);

class SmsParser {
  /// Verifica si el cuerpo de un SMS parece notificar un pago/compra.
  static bool looksLikePayment(String body) {
    final lower = body.toLowerCase();
    return _paymentKeywords.any(lower.contains);
  }

  /// Intenta parsear un SMS usando primero un [customRegex] (configurado
  /// por el usuario para un banco específico) y, si no hay o no matchea,
  /// cae al parser genérico.
  static ParsedPayment? parse(String body, {String? customRegex, DateTime? receivedAt}) {
    final date = receivedAt ?? DateTime.now();

    if (customRegex != null && customRegex.isNotEmpty) {
      final regex = RegExp(customRegex, caseSensitive: false);
      final match = regex.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final amount = _toDouble(match.group(1)!);
        if (amount != null) {
          return ParsedPayment(
            amount: amount,
            merchant: _extractMerchant(body),
            date: date,
          );
        }
      }
    }

    if (!looksLikePayment(body)) return null;

    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;
    final amount = _toDouble(amountMatch.group(1)!);
    if (amount == null || amount <= 0) return null;

    return ParsedPayment(
      amount: amount,
      merchant: _extractMerchant(body),
      date: date,
    );
  }

  static String? _extractMerchant(String body) {
    final match = _merchantRegex.firstMatch(body);
    return match?.group(1)?.trim();
  }

  /// Convierte "45.000", "45,000.50", "45000" a double, asumiendo que el
  /// separador de miles es el que no aparece como último grupo de 1-2 dígitos.
  static double? _toDouble(String raw) {
    var value = raw.trim();
    final lastDot = value.lastIndexOf('.');
    final lastComma = value.lastIndexOf(',');
    final decimalSeparatorIndex = lastDot > lastComma ? lastDot : lastComma;

    if (decimalSeparatorIndex == -1) {
      return double.tryParse(value);
    }

    final decimalPart = value.substring(decimalSeparatorIndex + 1);
    final looksLikeDecimals = decimalPart.length <= 2;

    final integerPart = value
        .substring(0, decimalSeparatorIndex)
        .replaceAll(RegExp(r'[.,]'), '');

    if (looksLikeDecimals) {
      return double.tryParse('$integerPart.$decimalPart');
    }
    // El separador encontrado era de miles, no de decimales.
    return double.tryParse(
        (integerPart + decimalPart).replaceAll(RegExp(r'[.,]'), ''));
  }
}
