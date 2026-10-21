import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/bank_card_widget.dart';
import '../../shared/widgets/category_icon.dart';

/// Pantalla de detalle de una tarjeta: la tarjeta grande arriba y debajo
/// la lista de movimientos asociados a ella (al estilo de las capturas de
/// Lemon/Nu que mandó el usuario).
class CardDetailScreen extends ConsumerWidget {
  final CardItem card;
  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(transactionsByCardProvider(card.id));

    return Scaffold(
      appBar: AppBar(title: Text(card.name)),
      body: txsAsync.when(
        data: (items) {
          final now = DateTime.now();
          final monthTotal = items
              .where((t) =>
                  t.transaction.type == TxType.expense &&
                  t.transaction.date.year == now.year &&
                  t.transaction.date.month == now.month)
              .fold<double>(0, (sum, t) => sum + t.transaction.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              BankCardWidget(card: card),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gastado este mes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        Formatters.money(monthTotal),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Transacciones',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Aún no hay movimientos en esta tarjeta',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CategoryIcon(
                            icon: item.category.icon,
                            colorHex: item.category.color,
                          ),
                          title: Text(
                            item.transaction.description.isEmpty
                                ? item.category.name
                                : item.transaction.description,
                          ),
                          subtitle: Text(
                            Formatters.dateTime.format(item.transaction.date),
                          ),
                          trailing: AmountText(
                            amount: item.transaction.amount,
                            type: item.transaction.type,
                          ),
                        ),
                      ),
                    )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
