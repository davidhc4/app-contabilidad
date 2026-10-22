import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

/// Diálogo para definir, cambiar o quitar el presupuesto mensual.
/// Se usa desde Ajustes y desde la tarjeta de presupuesto del Resumen.
Future<void> showBudgetDialog(
  BuildContext context,
  WidgetRef ref,
  double? current,
) async {
  final controller = TextEditingController(
    text: current == null ? '' : current.toStringAsFixed(0),
  );
  final result = await showDialog<_BudgetDialogResult>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Presupuesto mensual'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Es el máximo que planeas gastar cada mes. Cada gasto que '
            'registres se resta de este monto y en Resumen verás cuánto te '
            'queda disponible.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: r'$ ',
              hintText: 'Ej. 1.000.000',
            ),
          ),
        ],
      ),
      actions: [
        if (current != null)
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_BudgetDialogResult.remove()),
            child: const Text('Quitar'),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(
                controller.text.replaceAll('.', '').replaceAll(',', '.'));
            Navigator.of(dialogContext).pop(_BudgetDialogResult.save(amount));
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  controller.dispose();

  if (result == null) return;
  final repo = ref.read(settingsRepositoryProvider);
  if (result.remove) {
    await repo.setMonthlyBudget(null);
  } else if (result.amount != null && result.amount! > 0) {
    await repo.setMonthlyBudget(result.amount);
  }
}

class _BudgetDialogResult {
  final double? amount;
  final bool remove;
  _BudgetDialogResult.save(this.amount) : remove = false;
  _BudgetDialogResult.remove()
      : amount = null,
        remove = true;
}
