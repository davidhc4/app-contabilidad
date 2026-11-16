import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_formatter.dart';

/// Simulador de intereses: estima cuánto crece tu dinero en un CDT o en una
/// cuenta de ahorro que paga intereses (tipo "cajitas"). Es solo una
/// estimación educativa; no es una oferta ni asesoría financiera.
class InterestSimulatorScreen extends StatefulWidget {
  const InterestSimulatorScreen({super.key});

  @override
  State<InterestSimulatorScreen> createState() =>
      _InterestSimulatorScreenState();
}

class _InterestSimulatorScreenState extends State<InterestSimulatorScreen> {
  int _mode = 0; // 0 = CDT, 1 = Ahorro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulador de intereses')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('CDT')),
              ButtonSegment(value: 1, label: Text('Ahorro')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 20),
          if (_mode == 0) const _CdtSimulator() else const _SavingsSimulator(),
          const SizedBox(height: 24),
          Text(
            'Es una estimación educativa, no una oferta ni asesoría '
            'financiera. Las tasas reales y los impuestos pueden variar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Convierte el texto de una tasa ("12,5") a número.
double? _parseRate(TextEditingController c) {
  final raw = c.text.replaceAll('.', '').replaceAll(',', '.').trim();
  if (raw.isEmpty) return null;
  return double.tryParse(raw);
}

Widget _moneyField(TextEditingController c, String label,
    {VoidCallback? onChanged}) {
  return TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: const [ThousandsInputFormatter()],
    onChanged: (_) => onChanged?.call(),
    decoration: InputDecoration(labelText: label, prefixText: r'$ '),
  );
}

Widget _rateField(TextEditingController c, String label,
    {VoidCallback? onChanged, String suffix = '%'}) {
  return TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    onChanged: (_) => onChanged?.call(),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
  );
}

class _ResultRow extends StatelessWidget {
  final String label;
  final double value;
  final bool strong;
  final Color? color;
  const _ResultRow(this.label, this.value, {this.strong = false, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            Formatters.money(value),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- CDT ----------------

class _CdtSimulator extends StatefulWidget {
  const _CdtSimulator();

  @override
  State<_CdtSimulator> createState() => _CdtSimulatorState();
}

class _CdtSimulatorState extends State<_CdtSimulator> {
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _term = TextEditingController();
  final _retention = TextEditingController(text: '4');
  int _unit = 0; // 0 = meses, 1 = días

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _term.dispose();
    _retention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = parseThousands(_amount.text)?.toDouble();
    final ea = _parseRate(_rate);
    final term = double.tryParse(_term.text.replaceAll(',', '.'));
    final ret = _parseRate(_retention) ?? 0;

    double? gross, interestGross, retention, interestNet, total;
    if (amount != null && amount > 0 && ea != null && term != null && term > 0) {
      final years = (_unit == 0 ? term * 30.4375 : term) / 365.25;
      total = amount * math.pow(1 + ea / 100, years);
      gross = total;
      interestGross = gross - amount;
      retention = interestGross * (ret / 100);
      interestNet = interestGross - retention;
      total = amount + interestNet;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _moneyField(_amount, 'Monto a invertir',
            onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _rateField(_rate, 'Tasa efectiva anual (E.A.)',
            onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _term,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Plazo'),
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Meses')),
                ButtonSegment(value: 1, label: Text('Días')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _rateField(_retention, 'Retención en la fuente',
            onChanged: () => setState(() {})),
        const SizedBox(height: 20),
        if (total == null)
          Text('Llena los datos para ver el resultado.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ResultRow('Rendimiento bruto', interestGross!),
                  const Divider(height: 16),
                  _ResultRow('Retención en la fuente', -retention!),
                  const Divider(height: 16),
                  _ResultRow('Ganancia neta', interestNet!,
                      color: AppColors.income),
                  const Divider(height: 16),
                  _ResultRow('Total a recibir', total, strong: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- Ahorro (cajitas) ----------------

class _SavingsSimulator extends StatefulWidget {
  const _SavingsSimulator();

  @override
  State<_SavingsSimulator> createState() => _SavingsSimulatorState();
}

class _SavingsSimulatorState extends State<_SavingsSimulator> {
  final _initial = TextEditingController();
  final _monthly = TextEditingController();
  final _rate = TextEditingController();
  final _months = TextEditingController();

  @override
  void dispose() {
    _initial.dispose();
    _monthly.dispose();
    _rate.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = parseThousands(_initial.text)?.toDouble() ?? 0;
    final monthly = parseThousands(_monthly.text)?.toDouble() ?? 0;
    final ea = _parseRate(_rate);
    final months = int.tryParse(_months.text);

    double? finalBalance, contributed, earned;
    if (ea != null && months != null && months > 0 && (initial > 0 || monthly > 0)) {
      // Tasa mensual equivalente a la efectiva anual.
      final rm = math.pow(1 + ea / 100, 1 / 12) - 1;
      var balance = initial;
      for (var i = 0; i < months; i++) {
        balance = balance * (1 + rm) + monthly;
      }
      finalBalance = balance;
      contributed = initial + monthly * months;
      earned = finalBalance - contributed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _moneyField(_initial, 'Monto inicial', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _moneyField(_monthly, 'Aporte cada mes (opcional)',
            onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _rateField(_rate, 'Tasa efectiva anual (E.A.)',
            onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        TextField(
          controller: _months,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Tiempo (meses)'),
        ),
        const SizedBox(height: 20),
        if (finalBalance == null)
          Text('Llena los datos para ver el resultado.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ResultRow('Total aportado', contributed!),
                  const Divider(height: 16),
                  _ResultRow('Intereses ganados', earned!,
                      color: AppColors.income),
                  const Divider(height: 16),
                  _ResultRow('Saldo final', finalBalance, strong: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
