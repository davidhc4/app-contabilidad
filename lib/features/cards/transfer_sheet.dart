import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../providers/app_providers.dart';
import 'account_balances.dart';
import 'card_style.dart';

/// Abre el formulario para mover dinero de una tarjeta/cuenta a otra.
Future<void> showTransferSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const TransferSheet(),
  );
}

const _cashId = '_efectivo';

class _Account {
  final String id; // _cashId para "Efectivo / sin tarjeta"
  final String label;
  const _Account(this.id, this.label);

  String? get cardId => id == _cashId ? null : id;
}

class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _from;
  String? _to;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<_Account> accounts) async {
    final amount = parseThousands(_amountController.text)?.toDouble();
    final messenger = ScaffoldMessenger.of(context);
    if (_from == null || _to == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Elige de dónde sale y a dónde llega el dinero')),
      );
      return;
    }
    if (_from == _to) {
      messenger.showSnackBar(
        const SnackBar(content: Text('El origen y el destino deben ser distintos')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe el monto a transferir')),
      );
      return;
    }

    final from = accounts.firstWhere((a) => a.id == _from);
    final to = accounts.firstWhere((a) => a.id == _to);
    final note = _noteController.text.trim();
    final description = note.isEmpty
        ? 'Transferencia de ${from.label} a ${to.label}'
        : note;

    setState(() => _saving = true);
    try {
      await ref.read(transactionRepositoryProvider).addTransfer(
            fromCardId: from.cardId,
            toCardId: to.cardId,
            amount: amount,
            date: DateTime.now(),
            description: description,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Listo: ${Formatters.money(amount)} de ${from.label} a ${to.label}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo transferir: $e')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = ref.watch(cardsProvider).valueOrNull ?? const [];
    final styles = ref.watch(cardStylesProvider);
    final movements = ref.watch(accountMovementsProvider);

    final accounts = <_Account>[
      const _Account(_cashId, 'Efectivo / sin tarjeta'),
      for (final c in cards) _Account(c.id, '${c.name} ••${c.lastFourDigits}'),
    ];

    double? balanceOf(String? id) {
      if (id == null) return null;
      final cardId = id == _cashId ? null : id;
      return cardBalance(cardId, movements, styles);
    }

    final fromBalance = balanceOf(_from);

    Widget chips(String? selected, ValueChanged<String> onSelect) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final a in accounts)
            ChoiceChip(
              label: Text(a.label),
              selected: selected == a.id,
              onSelected: (_) => onSelect(a.id),
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Transferir entre tarjetas',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Mueve dinero de un lugar a otro sin que cuente como ingreso '
              'ni como gasto. Solo cambia cuánto hay en cada tarjeta.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('Sale de', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            chips(_from, (id) => setState(() => _from = id)),
            if (fromBalance != null) ...[
              const SizedBox(height: 6),
              Text('Disponible: ${Formatters.money(fromBalance)}',
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            Text('Llega a', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            chips(_to, (id) => setState(() => _to = id)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsInputFormatter()],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(prefixText: r'$ ', hintText: '0'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Nota (opcional), ej. Pasé ahorros a Nequi',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : () => _submit(accounts),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transferir'),
            ),
          ],
        ),
      ),
    );
  }
}
