import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/bank_card_widget.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/soft_fab.dart';
import '../../core/utils/formatters.dart';
import 'account_balances.dart';
import 'card_style.dart';
import 'transfer_sheet.dart';
import 'card_detail_screen.dart';
import 'card_form_sheet.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tarjetas')),
      floatingActionButton: SoftFab(
        icon: Icons.add_card_rounded,
        label: 'Nueva tarjeta',
        onPressed: () => showCardFormSheet(context),
      ),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.credit_card_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no has agregado ninguna tarjeta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca "Nueva tarjeta" para agregarlas, ponerles foto o '
                      'stickers y ver sus movimientos por separado.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: cards.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, i) {
              if (i == 0) return _BalancesSummary(cards: cards);
              final card = cards[i - 1];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardDetailScreen(card: card),
                      ),
                    ),
                    child: BankCardWidget(card: card),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => showCardFormSheet(context, editing: card),
                        icon: const Icon(Icons.palette_outlined, size: 18),
                        label: const Text('Personalizar'),
                      ),
                      TextButton.icon(
                        onPressed: () => deleteCardWithConfirm(context, ref, card),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Pide confirmación y elimina la tarjeta (sus movimientos se conservan).
/// Devuelve `true` si se eliminó.
Future<bool> deleteCardWithConfirm(
  BuildContext context,
  WidgetRef ref,
  CardItem card,
) async {
  final ok = await confirmDialog(
    context,
    title: 'Eliminar tarjeta',
    message: 'Se eliminará "${card.name}". Sus movimientos no se borran: '
        'quedarán sin tarjeta asignada.',
  );
  if (!ok) return false;
  await ref.read(cardRepositoryProvider).delete(card.id);
  await ref.read(cardStylesProvider.notifier).remove(card.id);
  return true;
}

/// Resumen de cuánto dinero hay en cada tarjeta/cuenta y botón para
/// transferir entre ellas.
class _BalancesSummary extends ConsumerWidget {
  final List<CardItem> cards;
  const _BalancesSummary({required this.cards});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final movements = ref.watch(accountMovementsProvider);
    final styles = ref.watch(cardStylesProvider);

    final rows = <MapEntry<String, double>>[
      MapEntry('Efectivo / sin tarjeta', cardBalance(null, movements, styles)),
      for (final c in cards)
        MapEntry('${c.name} ••${c.lastFourDigits}',
            cardBalance(c.id, movements, styles)),
    ];
    final total = rows.fold<double>(0, (sum, r) => sum + r.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Dónde está tu dinero?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Saldo de cada tarjeta según tus ingresos, gastos y '
              'transferencias.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(r.key)),
                    Text(
                      Formatters.money(r.value),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: r.value < 0 ? theme.colorScheme.error : null,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text('Total',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text(Formatters.money(total),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showTransferSheet(context),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transferir entre tarjetas'),
            ),
          ],
        ),
      ),
    );
  }
}
