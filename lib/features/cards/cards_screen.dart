import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/bank_card_widget.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'card_style.dart';
import 'card_detail_screen.dart';
import 'card_form_sheet.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tarjetas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCardFormSheet(context),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Nueva tarjeta'),
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
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, i) {
              final card = cards[i];
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
