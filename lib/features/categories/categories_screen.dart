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

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Gastos'), Tab(text: 'Ingresos')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormSheet(
          context,
          type: _tabController.index == 0 ? TxType.expense : TxType.income,
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryGrid(provider: expenseCategoriesProvider),
          _CategoryGrid(provider: incomeCategoriesProvider),
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
