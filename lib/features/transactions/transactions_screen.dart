import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'transaction_form_sheet.dart';

enum _Filter { all, income, expense }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de movimientos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por descripción',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                ),
                const SizedBox(height: 10),
                SegmentedButton<_Filter>(
                  segments: const [
                    ButtonSegment(value: _Filter.all, label: Text('Todo')),
                    ButtonSegment(value: _Filter.income, label: Text('Ingresos')),
                    ButtonSegment(value: _Filter.expense, label: Text('Gastos')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca un movimiento para editarlo. Para borrarlo, '
                  'arrástralo hacia la izquierda.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: txsAsync.when(
              data: (items) {
                final filtered = items.where((t) {
                  if (_filter == _Filter.income && t.transaction.type != TxType.income) {
                    return false;
                  }
                  if (_filter == _Filter.expense && t.transaction.type != TxType.expense) {
                    return false;
                  }
                  if (_query.isNotEmpty) {
                    final haystack =
                        '${t.transaction.description} ${t.category.name}'.toLowerCase();
                    if (!haystack.contains(_query)) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No hay movimientos'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    return Dismissible(
                      key: ValueKey(item.transaction.id),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline_rounded),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => confirmDialog(
                        context,
                        title: 'Eliminar movimiento',
                        message: 'Este movimiento se borrará y no se puede '
                            'deshacer.',
                      ),
                      onDismissed: (_) => ref
                          .read(transactionRepositoryProvider)
                          .delete(item.transaction.id),
                      child: Card(
                        child: ListTile(
                          onTap: () => showTransactionForm(
                            context,
                            type: item.transaction.type,
                            editing: item.transaction,
                          ),
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
                            '${item.category.name} · ${Formatters.shortDate.format(item.transaction.date)}',
                          ),
                          trailing: AmountText(
                            amount: item.transaction.amount,
                            type: item.transaction.type,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
