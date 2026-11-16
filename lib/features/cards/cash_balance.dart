import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../providers/app_providers.dart';
import 'account_balances.dart';

/// Ajusta el saldo del efectivo (la cuenta "Efectivo"). Igual que con las
/// tarjetas, si el saldo cambia se crea un movimiento de "Modificación de
/// saldo" con la diferencia. El efectivo no tiene saldo inicial aparte: su
/// saldo es la suma de sus movimientos.
Future<void> showCashBalanceDialog(BuildContext context, WidgetRef ref) async {
  final current = cardBalance(
    null,
    ref.read(accountMovementsProvider),
    ref.read(cardStylesProvider),
  );
  final controller = TextEditingController();

  final target = await showDialog<double>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Saldo del efectivo'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: const [ThousandsInputFormatter()],
        decoration: InputDecoration(
          prefixText: r'$ ',
          labelText: 'Dinero en efectivo',
          helperText: 'Saldo actual: ${Formatters.money(current)}',
          helperMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value = parseThousands(controller.text)?.toDouble();
            Navigator.of(dialogContext).pop(value);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (target == null) return;

  final delta = target - current;
  if (delta.abs() >= 1) {
    await ref
        .read(transactionRepositoryProvider)
        .addAdjustment(cardId: null, delta: delta);
  }
}
