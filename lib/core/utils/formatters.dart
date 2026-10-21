import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final currency = NumberFormat.currency(
    locale: 'es',
    symbol: r'$',
    decimalDigits: 0,
  );

  static final shortDate = DateFormat('d MMM', 'es');
  static final fullDate = DateFormat('d MMMM yyyy', 'es');
  static final monthYear = DateFormat('MMMM yyyy', 'es');

  static String money(double amount) => currency.format(amount);
}
