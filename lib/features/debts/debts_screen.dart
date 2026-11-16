import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'debt_detail_screen.dart';
import 'debt_form_sheet.dart';
import 'debt_model.dart';

/// Pestaña de Deudas: lo que te deben y lo que debes, con sus intereses.
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final debts = ref.watch(debtsProvider);
    final totals = ref.watch(debtTotalsProvider);

    final theyOwe = [for (final d in debts) if (d.theyOweMe) d];
    final iOwe = [for (final d in debts) if (!d.theyOweMe) d];
    int byState(Debt a, Debt b) {
      if (a.paid != b.paid) return a.paid ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    }

    theyOwe.sort(byState);
    iOwe.sort(byState);

    return Scaffold(
      appBar: AppBar(title: const Text('Deudas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDebtForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva deuda'),
      ),
      body: debts.isEmpty
          ? _empty(theme)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _TotalsCard(totals: totals),
                const SizedBox(height: 20),
                if (theyOwe.isNotEmpty) ...[
                  _SectionTitle('Me deben', color: AppColors.income),
                  const SizedBox(height: 8),
                  for (final d in theyOwe) _DebtTile(debt: d),
                  const SizedBox(height: 20),
                ],
                if (iOwe.isNotEmpty) ...[
                  _SectionTitle('Yo debo', color: AppColors.expense),
                  const SizedBox(height: 8),
                  for (final d in iOwe) _DebtTile(debt: d),
                ],
              ],
            ),
    );
  }

  Widget _empty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined,
                size: 56, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              'Aquí llevas lo que te deben y lo que debes.\n'
              'Toca "Nueva deuda" para empezar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final DebtTotals totals;
  const _TotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, double value, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                Formatters.money(value),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                cell('Me deben', totals.theyOweMe, AppColors.income),
                cell('Yo debo', totals.iOwe, AppColors.expense),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance', style: theme.textTheme.bodyMedium),
                Text(
                  Formatters.money(totals.net),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: totals.net >= 0 ? AppColors.income : AppColors.expense,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  const _DebtTile({required this.debt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = debt.paid
        ? theme.disabledColor
        : (debt.theyOweMe ? AppColors.income : AppColors.expense);
    final subtitle = <String>[
      Formatters.shortDate.format(debt.createdAt),
      if (debt.hasInterest && !debt.paid) 'con interés',
      if (debt.paid) 'pagada',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DebtDetailScreen(debtId: debt.id)),
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            debt.person.isEmpty ? '?' : debt.person[0].toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          debt.person,
          style: TextStyle(
            decoration: debt.paid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          Formatters.money(debt.currentTotal()),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }
}
