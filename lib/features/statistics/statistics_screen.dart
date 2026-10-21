import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_map.dart';
import '../../data/repositories/statistics_models.dart';
import '../../providers/app_providers.dart';
import '../dashboard/dashboard_screen.dart';

/// Pestaña "Estadísticas": un análisis a fondo de los movimientos del
/// usuario (con fecha y hora), filtrable por período.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final aggregateAsync = ref.watch(statsAggregateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _PeriodSelector(selected: period),
          const SizedBox(height: 20),
          aggregateAsync.when(
            data: (stats) => _StatsBody(period: period, stats: stats),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  final StatsPeriod selected;
  const _PeriodSelector({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StatsPeriod.values.map((p) {
          final isSelected = p == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.label),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(statsPeriodProvider.notifier).state = p,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final StatsPeriod period;
  final StatsAggregate stats;
  const _StatsBody({required this.period, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryGrid(stats: stats),
        const SizedBox(height: 24),
        _SectionTitle('Tendencia'),
        const SizedBox(height: 12),
        _TrendChart(stats: stats),
        const SizedBox(height: 24),
        _SectionTitle('Gastos por día de la semana'),
        const SizedBox(height: 12),
        _WeekdayChart(stats: stats),
        const SizedBox(height: 24),
        _SectionTitle('Gastos por hora del día'),
        const SizedBox(height: 12),
        _HourChart(stats: stats),
        const SizedBox(height: 24),
        _SectionTitle('Top categorías'),
        const SizedBox(height: 12),
        _TopCategories(stats: stats),
        const SizedBox(height: 24),
        _SectionTitle('Transacciones más grandes'),
        const SizedBox(height: 12),
        _TopTransactions(stats: stats),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final StatsAggregate stats;
  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: 'Ingresos',
          value: Formatters.money(stats.income),
          color: AppColors.income,
          icon: Icons.arrow_downward_rounded,
        ),
        _StatCard(
          label: 'Gastos',
          value: Formatters.money(stats.expense),
          color: AppColors.expense,
          icon: Icons.arrow_upward_rounded,
        ),
        _StatCard(
          label: 'Balance neto',
          value: Formatters.money(stats.net),
          color: stats.net >= 0 ? AppColors.income : AppColors.expense,
          icon: Icons.account_balance_wallet_rounded,
        ),
        _StatCard(
          label: 'Gasto diario promedio',
          value: Formatters.money(stats.avgDailyExpense),
          color: AppColors.warning,
          icon: Icons.calendar_today_rounded,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final StatsAggregate stats;
  const _TrendChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.trend.isEmpty) return const _EmptyStateCard();

    final points = stats.trend;
    final maxY = points
        .map((p) => p.income > p.expense ? p.income : p.expense)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final safeMaxY = maxY <= 0 ? 1.0 : maxY * 1.2;
    // Evita saturar el eje con demasiadas etiquetas si hay muchos puntos.
    final labelStep = (points.length / 6).ceil().clamp(1, 1000);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: safeMaxY,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: labelStep.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      if (i % labelStep != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(points[i].label,
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final p = points[s.x.round()];
                    return LineTooltipItem(
                      '${p.label}\n${Formatters.money(s.y)}',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  barWidth: 2.5,
                  color: AppColors.expense,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.expense.withValues(alpha: 0.12),
                  ),
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].expense),
                  ],
                ),
                LineChartBarData(
                  isCurved: true,
                  barWidth: 2.5,
                  color: AppColors.income,
                  dotData: const FlDotData(show: false),
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].income),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  final StatsAggregate stats;
  const _WeekdayChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = stats.weekdayStats;
    final maxVal =
        items.fold<double>(0, (a, b) => a > b.average ? a : b.average);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: safeMax,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(items[i].label,
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${items[groupIndex].label}: ${Formatters.money(rod.toY)}\npromedio por día',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < items.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: items[i].average,
                      color: AppColors.seed,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourChart extends StatelessWidget {
  final StatsAggregate stats;
  const _HourChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = stats.hourStats;
    final maxVal = items.fold<double>(0, (a, b) => a > b.total ? a : b.total);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: safeMax,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(items[i].label,
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${items[groupIndex].label}\n${Formatters.money(rod.toY)}',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < items.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: items[i].total,
                      color: AppColors.warning,
                      width: 26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopCategories extends StatelessWidget {
  final StatsAggregate stats;
  const _TopCategories({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.topCategories.isEmpty) return const _EmptyStateCard();

    final total = stats.topCategories.fold<double>(0, (a, b) => a + b.total);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: stats.topCategories.take(8).map((c) {
            final pct = total == 0 ? 0.0 : c.total / total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryIconDot(colorHex: c.category.color),
                      const SizedBox(width: 10),
                      Expanded(child: Text(c.category.name)),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(width: 8),
                      Text(Formatters.money(c.total),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0, 1),
                      minHeight: 6,
                      backgroundColor:
                          Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      color: colorFromHex(c.category.color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopTransactions extends StatelessWidget {
  final StatsAggregate stats;
  const _TopTransactions({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.topTransactions.isEmpty) return const _EmptyStateCard();

    return Card(
      child: Column(
        children: [
          for (final item in stats.topTransactions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CategoryIconDot(colorHex: item.category.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.transaction.description.isEmpty
                              ? item.category.name
                              : item.transaction.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          Formatters.dateTime.format(item.transaction.date),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.money(item.transaction.amount),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.expense),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.insights_outlined,
                size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('No hay suficientes datos en este período'),
          ],
        ),
      ),
    );
  }
}
