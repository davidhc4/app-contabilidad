import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/category_icon.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_map.dart';
import '../../shared/widgets/soft_fab.dart';
import 'category_form_sheet.dart';
import 'category_info.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _type = TxType.expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: SoftFab(
        icon: Icons.add_rounded,
        label: 'Nueva categoría',
        onPressed: () => showCategoryFormSheet(context, type: _type),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: TxType.expense,
                  label: Text('Gastos'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment(
                  value: TxType.income,
                  label: Text('Ingresos'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              'Las categorías sirven para clasificar cada movimiento y ver '
              'en qué gastas o de dónde recibes dinero. Toca una para ver '
              'qué incluye.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _CategoryGrid(
              provider: _type == TxType.expense
                  ? expenseCategoriesProvider
                  : incomeCategoriesProvider,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  final StreamProvider<List<Category>> provider;
  const _CategoryGrid({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(provider);
    return categoriesAsync.when(
      data: (categories) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final c = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => showCategoryDetail(context, c),
            child: Column(
            children: [
              CategoryIcon(icon: c.icon, colorHex: c.color, size: 56),
              const SizedBox(height: 8),
              Text(
                c.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (c.isCustom)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('Personalizada',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
            ],
          ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

/// Hoja con la imagen (ícono), el nombre y la explicación de la categoría,
/// más cuántos movimientos tiene este mes.
Future<void> showCategoryDetail(BuildContext context, Category category) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CategoryDetailSheet(category: category),
  );
}

class _CategoryDetailSheet extends ConsumerWidget {
  final Category category;
  const _CategoryDetailSheet({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpense = category.type == TxType.expense;
    final accent = colorFromHex(category.color);
    final now = DateTime.now();

    final txs = ref.watch(allTransactionsProvider).valueOrNull ??
        const <TransactionWithCategory>[];
    var count = 0;
    var total = 0.0;
    for (final t in txs) {
      final d = t.transaction.date;
      if (t.category.id == category.id &&
          d.year == now.year &&
          d.month == now.month) {
        count++;
        total += t.transaction.amount;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CategoryIcon(icon: category.icon, colorHex: category.color, size: 84),
          const SizedBox(height: 16),
          Text(
            category.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.expense : AppColors.income)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isExpense ? 'Categoría de gastos' : 'Categoría de ingresos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isExpense ? AppColors.expense : AppColors.income,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            categoryDescription(category),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text('Este mes', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  count == 0
                      ? 'Aún no tienes movimientos aquí'
                      : '${Formatters.money(total)} en $count '
                          '${count == 1 ? 'movimiento' : 'movimientos'}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
