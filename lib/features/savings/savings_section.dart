import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';
import '../budget/budget_dialog.dart';

/// "Ahorro proyectado": a partir de lo que sobra del presupuesto del mes
/// (presupuesto − gastos) calcula cuánto se acumularía en 3 meses, 6 meses,
/// 1 año o en el plazo que el usuario escriba.
class SavingsSection extends ConsumerStatefulWidget {
  final DateTime month;
  final double expense;
  final double income;

  const SavingsSection({
    super.key,
    required this.month,
    required this.expense,
    required this.income,
  });

  @override
  ConsumerState<SavingsSection> createState() => _SavingsSectionState();
}

class _SavingsSectionState extends ConsumerState<SavingsSection> {
  final _amountController = TextEditingController();
  final _yearsController = TextEditingController(text: '2');
  final _monthsController = TextEditingController(text: '0');

  @override
  void dispose() {
    _amountController.dispose();
    _yearsController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  double? _parseMoney(String text) {
    final cleaned = text.trim().replaceAll('.', '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String _plural(int n, String one, String many) => n == 1 ? one : many;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = ref.watch(settingsStreamProvider).valueOrNull?.monthlyBudget;

    if (budget == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Primero define tu presupuesto mensual',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'El ahorro proyectado se calcula con lo que te sobra del '
                'presupuesto cada mes: presupuesto − gastos.',
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

    final leftover = budget - widget.expense;
    final monthName = Formatters.monthYear.format(widget.month);
    final override = _parseMoney(_amountController.text);
    final perMonth = override ?? leftover;

    final years = int.tryParse(_yearsController.text.trim()) ?? 0;
    final extraMonths = int.tryParse(_monthsController.text.trim()) ?? 0;
    final customMonths = years * 12 + extraMonths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Paso a paso: de dónde sale lo que sobra.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lo que te sobra en $monthName',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _Line(label: '1. Presupuesto mensual', value: budget),
                _Line(
                    label: '2. Gastos registrados',
                    value: -widget.expense,
                    color: AppColors.expense),
                const Divider(height: 20),
                _Line(
                  label: '3. Te sobra',
                  value: leftover,
                  color: leftover >= 0 ? AppColors.income : AppColors.expense,
                  bold: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresos registrados este mes: '
                  '${Formatters.money(widget.income)}. No cambian el '
                  'presupuesto; se ven en tu balance.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Si ahorras eso cada mes',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Ahorro por mes: ${Formatters.money(perMonth)}'
                  '${override == null ? ' (lo que te sobra)' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (perMonth <= 0)
                  Text(
                    'Este mes no te sobra dinero, así que no habría ahorro. '
                    'Baja tus gastos o sube tu presupuesto, o escribe abajo '
                    'un monto de ahorro mensual para simular.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                          child: _ResultTile(label: '3 meses', value: perMonth * 3)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _ResultTile(label: '6 meses', value: perMonth * 6)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _ResultTile(label: '1 año', value: perMonth * 12)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calcula con tu propio plazo',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _yearsController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Años'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _monthsController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Meses'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  onChanged: (_) => setState(() {}),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Ahorro por mes (opcional)',
                    prefixText: r'$ ',
                    helperText: 'Si lo dejas vacío se usa lo que te sobra '
                        '(${Formatters.money(leftover)})',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 16),
                if (customMonths <= 0)
                  const Text('Escribe cuántos años y/o meses quieres calcular.')
                else if (perMonth <= 0)
                  const Text('Sin un ahorro mensual mayor a cero no se acumula nada.')
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'En ${[
                            if (years > 0) '$years ${_plural(years, 'año', 'años')}',
                            if (extraMonths > 0)
                              '$extraMonths ${_plural(extraMonths, 'mes', 'meses')}',
                          ].join(' y ')} '
                          '($customMonths ${_plural(customMonths, 'mes', 'meses')}) '
                          'tendrías',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.money(perMonth * customMonths),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Es una simulación: supone que ahorras la misma cantidad '
                  'todos los meses, sin intereses.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool bold;

  const _Line({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 18 : 15,
      color: color,
    );
    final sign = value < 0 ? '− ' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: style.fontWeight,
                fontSize: style.fontSize,
              ),
            ),
          ),
          Text('$sign${Formatters.money(value.abs())}', style: style),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final double value;
  const _ResultTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.money(value),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.income),
            ),
          ),
        ],
      ),
    );
  }
}
