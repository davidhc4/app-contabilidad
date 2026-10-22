import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/category_icon.dart';
import 'category_form_sheet.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryFormSheet(context, type: _type),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva categoría'),
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
          return Column(
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
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
