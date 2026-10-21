import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/icon_map.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';

/// Crear una categoría/tipo personalizado de ingreso o gasto.
Future<void> showCategoryFormSheet(BuildContext context, {required String type}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CategoryFormSheet(type: type),
  );
}

const _palette = [
  'FF0A84FF',
  'FF30D158',
  'FFFF9F0A',
  'FFFF453A',
  'FFBF5AF2',
  'FF64D2FF',
  'FFFF375F',
  'FF8E8E93',
];

class CategoryFormSheet extends ConsumerStatefulWidget {
  final String type;
  const CategoryFormSheet({super.key, required this.type});

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _nameController = TextEditingController();
  String _icon = kCategoryIcons.keys.first;
  String _color = _palette.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await ref.read(categoryRepositoryProvider).addCustom(
          name: name,
          type: widget.type,
          icon: _icon,
          color: _color,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.type == TxType.expense;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isExpense ? 'Nuevo gasto personalizado' : 'Nuevo ingreso personalizado',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nombre, ej. Gimnasio'),
          ),
          const SizedBox(height: 16),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _palette.map((hex) {
              final selected = hex == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = hex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorFromHex(hex),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Icono', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kCategoryIcons.keys.map((key) {
              final selected = key == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorFromHex(_color).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: colorFromHex(_color), width: 2)
                        : null,
                  ),
                  child: Icon(iconFor(key), color: colorFromHex(_color)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _submit, child: const Text('Crear')),
        ],
      ),
    );
  }
}
