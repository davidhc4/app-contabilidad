import '../../core/utils/formatters.dart';
import '../local/database.dart';
import '../local/tables.dart';
import 'transaction_repository.dart';

/// Períodos disponibles para filtrar la pantalla de Estadísticas.
enum StatsPeriod { week, month, year, all }

extension StatsPeriodLabel on StatsPeriod {
  String get label => switch (this) {
        StatsPeriod.week => 'Esta semana',
        StatsPeriod.month => 'Este mes',
        StatsPeriod.year => 'Este año',
        StatsPeriod.all => 'Todo',
      };
}

/// Rango de fechas (fin exclusivo) que define un período de estadísticas.
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);

  int get daySpan => end.difference(start).inDays.clamp(1, 1 << 31);
}

/// Fecha más antigua razonable para usar como inicio de "Todo el tiempo"
/// cuando no se conoce la primera transacción real del usuario.
final _fallbackEarliest = DateTime(2020, 1, 1);

DateRange rangeForPeriod(StatsPeriod period, {DateTime? earliestDate}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case StatsPeriod.week:
      final start = today.subtract(Duration(days: today.weekday - 1));
      return DateRange(start, start.add(const Duration(days: 7)));
    case StatsPeriod.month:
      return DateRange(
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 1),
      );
    case StatsPeriod.year:
      return DateRange(DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
    case StatsPeriod.all:
      return DateRange(
        earliestDate ?? _fallbackEarliest,
        today.add(const Duration(days: 1)),
      );
  }
}

/// Un punto de la gráfica de tendencia (un día o un mes, según el período).
class TrendPoint {
  final DateTime bucketStart;
  final String label;
  final double income;
  final double expense;
  TrendPoint({
    required this.bucketStart,
    required this.label,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

/// Gasto total y promedio para un día de la semana (1 = lunes ... 7 = domingo).
class WeekdayStat {
  final int weekday;
  final double total;
  final int count;
  WeekdayStat(this.weekday, this.total, this.count);

  double get average => count == 0 ? 0 : total / count;

  String get label => const [
        'Lun',
        'Mar',
        'Mié',
        'Jue',
        'Vie',
        'Sáb',
        'Dom',
      ][weekday - 1];
}

/// Gasto total dentro de una franja horaria [startHour, endHour).
class HourBucketStat {
  final int startHour;
  final int endHour;
  final double total;
  HourBucketStat(this.startHour, this.endHour, this.total);

  String get label => '${_h(startHour)}-${_h(endHour)}';

  static String _h(int h) => h == 24 ? '0h' : '${h}h';
}

class _MutablePoint {
  double income = 0;
  double expense = 0;
}

/// Agregado completo de estadísticas para un rango de fechas: se construye
/// una sola vez a partir de la lista de transacciones del rango (que ya
/// viene de `TransactionRepository.watchInRange`) y de ahí se derivan todas
/// las gráficas y tarjetas de la pantalla de Estadísticas.
class StatsAggregate {
  final double income;
  final double expense;
  final int daySpan;
  final List<TrendPoint> trend;
  final List<WeekdayStat> weekdayStats;
  final List<HourBucketStat> hourStats;
  final List<CategoryTotal> topCategories;
  final List<TransactionWithCategory> topTransactions;

  StatsAggregate({
    required this.income,
    required this.expense,
    required this.daySpan,
    required this.trend,
    required this.weekdayStats,
    required this.hourStats,
    required this.topCategories,
    required this.topTransactions,
  });

  double get net => income - expense;
  double get avgDailyExpense => daySpan == 0 ? 0 : expense / daySpan;

  static const _hourBucketRanges = [
    [0, 6],
    [6, 12],
    [12, 18],
    [18, 24],
  ];

  factory StatsAggregate.build(
    List<TransactionWithCategory> items,
    DateRange range,
    StatsPeriod period,
  ) {
    double income = 0, expense = 0;
    final weekdayTotals = <int, double>{};
    final weekdayCounts = <int, int>{};
    final hourTotals = List<double>.filled(24, 0);
    final catTotals = <String, double>{};
    final catMap = <String, Category>{};
    final trendMap = <DateTime, _MutablePoint>{};

    final useMonthlyBuckets =
        period == StatsPeriod.year || period == StatsPeriod.all;

    for (final item in items) {
      final tx = item.transaction;
      if (tx.type == TxType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        weekdayTotals.update(
            tx.date.weekday, (v) => v + tx.amount, ifAbsent: () => tx.amount);
        weekdayCounts.update(tx.date.weekday, (v) => v + 1, ifAbsent: () => 1);
        hourTotals[tx.date.hour] += tx.amount;
        catTotals.update(item.category.id, (v) => v + tx.amount,
            ifAbsent: () => tx.amount);
        catMap[item.category.id] = item.category;
      }

      final bucketKey = useMonthlyBuckets
          ? DateTime(tx.date.year, tx.date.month)
          : DateTime(tx.date.year, tx.date.month, tx.date.day);
      final point = trendMap.putIfAbsent(bucketKey, () => _MutablePoint());
      if (tx.type == TxType.income) {
        point.income += tx.amount;
      } else {
        point.expense += tx.amount;
      }
    }

    final sortedKeys = trendMap.keys.toList()..sort();
    final trend = sortedKeys.map((k) {
      final p = trendMap[k]!;
      final label = useMonthlyBuckets
          ? Formatters.monthShort.format(k)
          : Formatters.shortDate.format(k);
      return TrendPoint(
          bucketStart: k, label: label, income: p.income, expense: p.expense);
    }).toList();

    final weekdayStats = List.generate(7, (i) {
      final wd = i + 1;
      return WeekdayStat(wd, weekdayTotals[wd] ?? 0, weekdayCounts[wd] ?? 0);
    });

    final hourStats = _hourBucketRanges.map((r) {
      double total = 0;
      for (var h = r[0]; h < r[1]; h++) {
        total += hourTotals[h];
      }
      return HourBucketStat(r[0], r[1], total);
    }).toList();

    final topCategories = catTotals.entries
        .map((e) => CategoryTotal(catMap[e.key]!, e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final topTransactions = items
        .where((i) => i.transaction.type == TxType.expense)
        .toList()
      ..sort((a, b) => b.transaction.amount.compareTo(a.transaction.amount));

    return StatsAggregate(
      income: income,
      expense: expense,
      daySpan: range.daySpan,
      trend: trend,
      weekdayStats: weekdayStats,
      hourStats: hourStats,
      topCategories: topCategories,
      topTransactions: topTransactions.take(10).toList(),
    );
  }
}
