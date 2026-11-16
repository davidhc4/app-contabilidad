import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'debt_form_sheet.dart';
import 'debt_model.dart';

/// Detalle de una deuda: capital, interés acumulado y total al día de hoy.
class DebtDetailScreen extends ConsumerWidget {
  final String debtId;
  const DebtDetailScreen({super.key, required this.debtId});

  String _interestLabel(Debt d) {
    final amount = d.interestKind == InterestKind.fixed
        ? Formatters.money(d.interestRate)
        : '${_trim(d.interestRate)} %';
    return '$amount cada ${d.period.label.toLowerCase()}';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? v.round().toString() : s.replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Debt? debt;
    for (final d in ref.watch(debtsProvider)) {
      if (d.id == debtId) {
        debt = d;
        break;
      }
    }

    if (debt == null) {
      return const Scaffold(body: Center(child: Text('Esta deuda ya no existe.')));
    }

    final color = debt.paid
        ? theme.disabledColor
        : (debt.theyOweMe ? AppColors.income : AppColors.expense);
    final interest = debt.interestSoFar();
    final total = debt.currentTotal();

    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.person),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => showDebtForm(context, editing: debt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  debt.theyOweMe ? 'Te debe' : 'Le debes',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.money(total),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (debt.paid)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Pagada', style: theme.textTheme.labelLarge),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  row('Capital', Formatters.money(debt.amount)),
                  if (debt.hasInterest && !debt.paid) ...[
                    const Divider(height: 16),
                    row('Interés acumulado', Formatters.money(interest)),
                    const Divider(height: 16),
                    row('Total hoy', Formatters.money(total), strong: true),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  row('Interés', debt.hasInterest ? _interestLabel(debt) : 'Sin interés'),
                  const Divider(height: 16),
                  row('Inicio', Formatters.dateTime.format(debt.createdAt)),
                  if (debt.note.isNotEmpty) ...[
                    const Divider(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(debt.note, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () =>
                ref.read(debtsProvider.notifier).setPaid(debt.id, !debt.paid),
            icon: Icon(debt.paid
                ? Icons.undo_rounded
                : Icons.check_circle_outline_rounded),
            label: Text(debt.paid ? 'Marcar como activa' : 'Marcar como pagada'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Eliminar deuda',
                message: 'Se borrará esta deuda. No se puede deshacer.',
              );
              if (ok != true) return;
              await ref.read(debtsProvider.notifier).remove(debt.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
