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
  static final monthShort = DateFormat('MMM', 'es');
  static final time = DateFormat('h:mm a', 'es');
  static final dateTime = DateFormat('d MMM, h:mm a', 'es');
  static final weekdayShort = DateFormat('EEE', 'es');

  static String money(double amount) => currency.format(amount);
}
