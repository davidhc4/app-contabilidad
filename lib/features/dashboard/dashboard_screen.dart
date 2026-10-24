import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_map.dart';
import '../../data/local/tables.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/soft_fab.dart';
import '../budget/budget_dialog.dart';
import '../cards/transfer_sheet.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_state.dart';
import '../savings/savings_section.dart';
import '../transactions/transaction_form_sheet.dart';

/// Sección visible en Resumen: 0 = el mes, 1 = ahorro proyectado.
final dashboardSectionProvider = StateProvider<int>((ref) => 0);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final byCategoryAsync = ref.watch(expenseByCategoryProvider);
    final section = ref.watch(dashboardSectionProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const _ProfileButton(),
        actions: [
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(Formatters.monthYear.format(month)),
          ),
          IconButton(
            tooltip: 'Mes siguiente',
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
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Este mes'),
                  icon: Icon(Icons.calendar_month_rounded),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Ahorro proyectado'),
                  icon: Icon(Icons.savings_outlined),
                ),
              ],
              selected: {section},
              onSelectionChanged: (s) =>
                  ref.read(dashboardSectionProvider.notifier).state = s.first,
            ),
            const SizedBox(height: 16),
            if (section == 1)
              summaryAsync.when(
                data: (summary) => SavingsSection(
                  month: month,
                  expense: summary.expense,
                  income: summary.income,
                ),
                loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error: $e'),
              )
            else ...[
            summaryAsync.when(
              data: (summary) => Column(
                children: [
                  _BalanceCard(summary: summary),
                  const SizedBox(height: 16),
                  _BudgetCard(spent: summary.expense, month: month),
                ],
              ),
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
            Text('Lo que ganaste menos lo que gastaste',
                style: Theme.of(context).textTheme.bodySmall),
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

/// Presupuesto mensual: muestra cuánto del tope se ha gastado y cuánto
/// queda disponible. Cada gasto registrado en el mes seleccionado se resta
/// automáticamente; los ingresos no afectan el presupuesto.
class _BudgetCard extends ConsumerWidget {
  final double spent;
  final DateTime month;
  const _BudgetCard({required this.spent, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(settingsStreamProvider).valueOrNull?.monthlyBudget;
    final theme = Theme.of(context);

    if (budget == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.savings_outlined),
                  const SizedBox(width: 8),
                  Text('Presupuesto mensual',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Define el dinero con el que cuentas cada mes. Cada gasto que '
                'registres se descuenta de ese monto y lo que sobre es lo que '
                'podrías ahorrar.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => showBudgetDialog(context, ref, null),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Definir presupuesto'),
              ),
            ],
          ),
        ),
      );
    }

    final remaining = budget - spent;
    final over = remaining < 0;
    final ratio = budget <= 0 ? 0.0 : (spent / budget);
    final percent = (ratio * 100).round();
    final barColor = over
        ? AppColors.expense
        : ratio >= 0.8
            ? const Color(0xFFFF9F0A)
            : AppColors.income;

    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;

    String? tip;
    if (over) {
      tip = 'Superaste tu presupuesto este mes.';
    } else if (isCurrentMonth && daysLeft > 0) {
      tip = 'Puedes gastar unos ${Formatters.money(remaining / daysLeft)} '
          'por día durante los $daysLeft días que quedan del mes.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Presupuesto del mes',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () => showBudgetDialog(context, ref, budget),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(over ? 'Te pasaste por' : 'Te sobra este mes',
                style: theme.textTheme.labelLarge),
            Text(
              Formatters.money(remaining.abs()),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: over ? AppColors.expense : null,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 10,
                color: barColor,
                backgroundColor: barColor.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gastado ${Formatters.money(spent)} de '
              '${Formatters.money(budget)} ($percent%)',
              style: theme.textTheme.bodySmall,
            ),
            if (tip != null) ...[
              const SizedBox(height: 6),
              Text(tip, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            Text(
              'Presupuesto − gastos = lo que sobra. Los ingresos que '
              'registres no cambian el presupuesto.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(dashboardSectionProvider.notifier).state = 1,
              icon: const Icon(Icons.trending_up_rounded),
              label: const Text('Ver cuánto ahorraría'),
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
    return SoftFab(
      icon: Icons.add_rounded,
      label: 'Agregar',
      onPressed: () => _openMenu(context),
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
              subtitle: const Text('Dinero que sale: compras, pagos, servicios'),
              onTap: () {
                Navigator.pop(context);
                showTransactionForm(context, type: TxType.expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.seed),
              title: const Text('Transferir entre tarjetas'),
              subtitle: const Text(
                  'Mueve dinero de una tarjeta a otra sin contarlo como ingreso ni gasto'),
              onTap: () {
                Navigator.pop(context);
                showTransferSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.income),
              title: const Text('Agregar ingreso'),
              subtitle: const Text('Dinero que entra: salario, ventas, regalos'),
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

/// Arriba a la izquierda: la foto y el nombre de tu perfil. Al tocarlo se
/// abre el perfil con tu inventario.
class _ProfileButton extends ConsumerWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).name;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProfileAvatar(size: 36, badge: true),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isEmpty ? 'Mi perfil' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Resumen',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
