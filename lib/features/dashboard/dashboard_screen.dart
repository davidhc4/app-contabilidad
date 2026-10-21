import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_map.dart';
import '../../data/local/tables.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../providers/app_providers.dart';
import '../transactions/transaction_form_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final byCategoryAsync = ref.watch(expenseByCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(Formatters.monthYear.format(month)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
        ],
      ),
      floatingActionButton: _AddMenuFab(),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            summaryAsync.when(
              data: (summary) => _BalanceCard(summary: summary),
              loading: () => const SizedBox(
                  height: 140, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 20),
            Text('Gastos por categoría',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            byCategoryAsync.when(
              data: (totals) => totals.isEmpty
                  ? const _EmptyState()
                  : _CategoryBreakdown(totals: totals),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final MonthSummary summary;
  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance del mes',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              Formatters.money(summary.net),
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Ingresos',
                    amount: summary.income,
                    color: AppColors.income,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Gastos',
                    amount: summary.expense,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _MiniStat(
      {required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: color)),
                Text(Formatters.money(amount),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<CategoryTotal> totals;
  const _CategoryBreakdown({required this.totals});

  @override
  Widget build(BuildContext context) {
    final total = totals.fold<double>(0, (p, e) => p + e.total);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: totals.map((t) {
                    final pct = total == 0 ? 0 : (t.total / total * 100);
                    return PieChartSectionData(
                      value: t.total,
                      color: colorFromHex(t.category.color),
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...totals.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CategoryIconDot(colorHex: t.category.color),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.category.name)),
                      Text(Formatters.money(t.total),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class CategoryIconDot extends StatelessWidget {
  final String colorHex;
  const CategoryIconDot({super.key, required this.colorHex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: colorFromHex(colorHex),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.savings_outlined,
                size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('Aún no tienes gastos registrados este mes'),
          ],
        ),
      ),
    );
  }
}

class _AddMenuFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openMenu(context),
      child: const Icon(Icons.add_rounded),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.expense),
              title: const Text('Agregar gasto'),
              onTap: () {
                Navigator.pop(context);
                showTransactionForm(context, type: TxType.expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.income),
              title: const Text('Agregar ingreso'),
              onTap: () {
                Navigator.pop(context);
                showTransactionForm(context, type: TxType.income);
              },
            ),
          ],
        ),
      ),
    );
  }
}
