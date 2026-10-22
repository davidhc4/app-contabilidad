import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/tables.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../providers/app_providers.dart';
import 'card_style.dart';

/// Lo que se movió en cada cuenta según los movimientos registrados:
/// ingresos y transferencias que entran suman; gastos y transferencias que
/// salen restan. La clave `null` es "Efectivo / sin tarjeta".
Map<String?, double> movementBalances(List<TransactionWithCategory> txs) {
  final result = <String?, double>{};
  for (final item in txs) {
    final tx = item.transaction;
    final delta = switch (tx.type) {
      TxType.income || TxType.transferIn => tx.amount,
      TxType.expense || TxType.transferOut => -tx.amount,
      _ => 0.0,
    };
    result.update(tx.cardId, (v) => v + delta, ifAbsent: () => delta);
  }
  return result;
}

final accountMovementsProvider = Provider<Map<String?, double>>((ref) {
  final txs = ref.watch(allTransactionsProvider).valueOrNull ??
      const <TransactionWithCategory>[];
  return movementBalances(txs);
});

/// Saldo actual de una tarjeta: saldo inicial + movimientos.
double cardBalance(
  String? cardId,
  Map<String?, double> movements,
  Map<String, CardStyle> styles,
) {
  final initial = cardId == null ? 0.0 : (styles[cardId]?.initialBalance ?? 0.0);
  return initial + (movements[cardId] ?? 0.0);
}
