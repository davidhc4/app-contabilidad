import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_formatter.dart';
import 'debt_model.dart';

/// Abre el formulario para crear o editar una deuda.
Future<void> showDebtForm(BuildContext context, {Debt? editing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DebtFormSheet(editing: editing),
  );
}

class _DebtFormSheet extends ConsumerStatefulWidget {
  final Debt? editing;
  const _DebtFormSheet({this.editing});

  @override
  ConsumerState<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<_DebtFormSheet> {
  late final _person = TextEditingController(text: widget.editing?.person ?? '');
  late final _note = TextEditingController(text: widget.editing?.note ?? '');
  late final _amount = TextEditingController(
    text: widget.editing == null
        ? ''
        : formatThousands(widget.editing!.amount.round().toString()),
  );
  late final _rate = TextEditingController(
    text: widget.editing == null || widget.editing!.interestRate == 0
        ? ''
        : (widget.editing!.interestKind == InterestKind.fixed
            ? formatThousands(widget.editing!.interestRate.round().toString())
            : _trimNumber(widget.editing!.interestRate)),
  );

  late bool _theyOweMe = widget.editing?.theyOweMe ?? true;
  late InterestKind _interestKind =
      widget.editing?.interestKind ?? InterestKind.none;
  late InterestPeriod _period = widget.editing?.period ?? InterestPeriod.month;
  late DateTime _createdAt = widget.editing?.createdAt ?? DateTime.now();
  bool _saving = false;

  static String _trimNumber(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? v.round().toString() : s.replaceAll('.', ',');
  }

  @override
  void dispose() {
    _person.dispose();
    _note.dispose();
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_createdAt),
    );
    if (!mounted) return;
    setState(() {
      _createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _createdAt.hour,
        time?.minute ?? _createdAt.minute,
      );
    });
  }

  double? _parseRate() {
    final raw = _rate.text.replaceAll('.', '').replaceAll(',', '.').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _save() async {
    final person = _person.text.trim();
    final amount = parseThousands(_amount.text)?.toDouble();
    if (person.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre y el monto')),
      );
      return;
    }
    var rate = 0.0;
    if (_interestKind != InterestKind.none) {
      rate = _parseRate() ?? 0;
      if (rate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe el interés acordado')),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final notifier = ref.read(debtsProvider.notifier);
    final debt = Debt(
      id: widget.editing?.id ?? notifier.newId(),
      person: person,
      theyOweMe: _theyOweMe,
      amount: amount,
      createdAt: _createdAt,
      interestKind: _interestKind,
      interestRate: rate,
      period: _period,
      paid: widget.editing?.paid ?? false,
      note: _note.text.trim(),
    );
    await notifier.upsert(debt);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleSmall;
    final isFixed = _interestKind == InterestKind.fixed;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.editing == null ? 'Nueva deuda' : 'Editar deuda',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Me deben')),
                ButtonSegment(value: false, label: Text('Yo debo')),
              ],
              selected: {_theyOweMe},
              onSelectionChanged: (s) => setState(() => _theyOweMe = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Persona',
                hintText: 'Ej. Juan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: 20),
            Text('Interés (opcional)', style: labelStyle),
            const SizedBox(height: 8),
            SegmentedButton<InterestKind>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: InterestKind.none, label: Text('Ninguno')),
                ButtonSegment(value: InterestKind.percent, label: Text('%')),
                ButtonSegment(value: InterestKind.fixed, label: Text('Monto')),
              ],
              selected: {_interestKind},
              onSelectionChanged: (s) => setState(() => _interestKind = s.first),
            ),
            if (_interestKind != InterestKind.none) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: isFixed
                    ? const [ThousandsInputFormatter()]
                    : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: 'Interés acordado',
                  prefixText: isFixed ? r'$ ' : null,
                  suffixText: isFixed ? null : '%',
                  helperText: isFixed
                      ? 'Dinero de interés por cada periodo'
                      : 'Porcentaje del monto por cada periodo',
                ),
              ),
              const SizedBox(height: 12),
              Text('Cada', style: labelStyle),
              const SizedBox(height: 8),
              SegmentedButton<InterestPeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: InterestPeriod.day, label: Text('Día')),
                  ButtonSegment(value: InterestPeriod.month, label: Text('Mes')),
                  ButtonSegment(value: InterestPeriod.year, label: Text('Año')),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
            ],
            const SizedBox(height: 20),
            Text('Inicio', style: labelStyle),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded),
              label: Text(Formatters.dateTime.format(_createdAt)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando…' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
