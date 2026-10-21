import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/tables.dart';
import '../transactions/transaction_form_sheet.dart';
import 'sms_listener_service.dart';

/// Muestra el bottom sheet de "¿agregar este gasto?" para un pago
/// detectado por SMS. Nunca guarda nada automáticamente: siempre requiere
/// que el usuario confirme, edite o descarte.
Future<void> showSmsPaymentConfirmSheet(
  BuildContext context,
  PendingSmsPayment payment,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    builder: (_) => _SmsConfirmSheet(payment: payment),
  );
}

class _SmsConfirmSheet extends StatelessWidget {
  final PendingSmsPayment payment;
  const _SmsConfirmSheet({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.seed.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_rounded, color: AppColors.seed, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Detectamos un posible pago',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            payment.merchant != null
                ? '${Formatters.money(payment.amount)} en ${payment.merchant}'
                : Formatters.money(payment.amount),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.fullDate.format(payment.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Descartar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showTransactionForm(
                      context,
                      type: TxType.expense,
                      prefillAmount: payment.amount,
                      prefillDescription: payment.merchant ?? '',
                      prefillDate: payment.date,
                      prefillRawSms: payment.rawBody,
                    );
                  },
                  child: const Text('Agregar gasto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
