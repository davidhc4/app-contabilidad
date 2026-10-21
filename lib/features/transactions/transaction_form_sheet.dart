import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/category_icon.dart';
import '../categories/category_form_sheet.dart';

/// Abre el formulario para crear/editar una transacción.
/// Si [prefill] viene de un SMS detectado, se usa para pre-llenar los campos.
Future<void> showTransactionForm(
  BuildContext context, {
  required String type,
  Transaction? editing,
  double? prefillAmount,
  String? prefillDescription,
  DateTime? prefillDate,
  String? prefillRawSms,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TransactionFormSheet(
      type: type,
      editing: editing,
      prefillAmount: prefillAmount,
      prefillDescription: prefillDescription,
      prefillDate: prefillDate,
      prefillRawSms: prefillRawSms,
    ),
  );
}

class TransactionFormSheet extends ConsumerStatefulWidget {
  final String type;
  final Transaction? editing;
  final double? prefillAmount;
  final String? prefillDescription;
  final DateTime? prefillDate;
  final String? prefillRawSms;

  const TransactionFormSheet({
    super.key,
    required this.type,
    this.editing,
    this.prefillAmount,
    this.prefillDescription,
    this.prefillDate,
    this.prefillRawSms,
  });

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late final _amountController = TextEditingController(
    text: (widget.editing?.amount ?? widget.prefillAmount)?.toStringAsFixed(0) ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.editing?.description ?? widget.prefillDescription ?? '',
  );
  late DateTime _date =
      widget.editing?.date ?? widget.prefillDate ?? DateTime.now();
  late String? _categoryId = widget.editing?.categoryId;
  late String _type = widget.editing?.type ?? widget.type;
  late String? _cardId = widget.editing?.cardId;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0 || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el monto y la categoría')),
      );
      return;
    }

    final repo = ref.read(transactionRepositoryProvider);
    if (widget.editing != null) {
      await repo.update(widget.editing!.copyWith(
        type: _type,
        amount: amount,
        categoryId: _categoryId!,
        description: _descriptionController.text,
        date: _date,
        cardId: Value(_cardId),
      ));
    } else {
      await repo.add(
        type: _type,
        amount: amount,
        categoryId: _categoryId!,
        description: _descriptionController.text,
        date: _date,
        source: widget.prefillRawSms != null ? TxSource.sms : TxSource.manual,
        rawSmsBody: widget.prefillRawSms,
        cardId: _cardId,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _type == TxType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final isExpense = _type == TxType.expense;
    final cardsAsync = ref.watch(cardsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.editing != null
                ? 'Editar movimiento'
                : isExpense
                    ? 'Nuevo gasto'
                    : 'Nuevo ingreso',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: TxType.expense, label: Text('Gasto')),
              ButtonSegment(value: TxType.income, label: Text('Ingreso')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _categoryId = null;
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              prefixText: r'$ ',
              hintText: '0',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'Descripción (opcional)'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: Text(Formatters.fullDate.format(_date)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) {
                setState(() => _date = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      _date.hour,
                      _date.minute,
                    ));
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_rounded),
            title: Text(Formatters.time.format(_date)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_date),
              );
              if (picked != null) {
                setState(() => _date = DateTime(
                      _date.year,
                      _date.month,
                      _date.day,
                      picked.hour,
                      picked.minute,
                    ));
              }
            },
          ),
          const SizedBox(height: 12),
          Text('Categoría', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...categories.map((c) => _CategoryChoice(
                      selected: _categoryId == c.id,
                      label: c.name,
                      icon: c.icon,
                      colorHex: c.color,
                      onTap: () => setState(() => _categoryId = c.id),
                    )),
                _AddCategoryChoice(type: _type),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          // El selector de tarjeta es opcional y solo aparece si el usuario
          // ya tiene al menos una tarjeta creada, para no confundir a quien
          // no usa esta función.
          cardsAsync.maybeWhen(
            data: (cards) {
              if (cards.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text('Tarjeta (opcional)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Sin tarjeta'),
                        selected: _cardId == null,
                        onSelected: (_) => setState(() => _cardId = null),
                      ),
                      ...cards.map((card) => ChoiceChip(
                            label: Text('${card.name} ••${card.lastFourDigits}'),
                            selected: _cardId == card.id,
                            onSelected: (_) =>
                                setState(() => _cardId = card.id),
                          )),
                    ],
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.editing != null ? 'Guardar cambios' : 'Agregar'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  final bool selected;
  final String label;
  final String icon;
  final String colorHex;
  final VoidCallback onTap;

  const _CategoryChoice({
    required this.selected,
    required this.label,
    required this.icon,
    required this.colorHex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryIcon(icon: icon, colorHex: colorHex, size: 28),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryChoice extends StatelessWidget {
  final String type;
  const _AddCategoryChoice({required this.type});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showCategoryFormSheet(context, type: type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 20),
            SizedBox(width: 6),
            Text('Nueva'),
          ],
        ),
      ),
    );
  }
}
