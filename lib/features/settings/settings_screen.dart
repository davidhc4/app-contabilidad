import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import '../sms_detection/sms_permission_helper.dart';
import 'sms_senders_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const _SectionTitle('Apariencia'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Oscuro'),
                    value: 'dark',
                    groupValue: settings.themeMode,
                    onChanged: (v) => ref
                        .read(settingsRepositoryProvider)
                        .setThemeMode(v!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Claro'),
                    value: 'light',
                    groupValue: settings.themeMode,
                    onChanged: (v) => ref
                        .read(settingsRepositoryProvider)
                        .setThemeMode(v!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Automático (sistema)'),
                    value: 'system',
                    groupValue: settings.themeMode,
                    onChanged: (v) => ref
                        .read(settingsRepositoryProvider)
                        .setThemeMode(v!),
                  ),
                ],
              ),
            ),
            const _SectionTitle('Detección de pagos por SMS'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Detectar pagos automáticamente'),
                    subtitle: const Text(
                        'Al llegar un SMS de tu banco, te preguntamos si quieres añadir el gasto'),
                    value: settings.smsDetectionEnabled,
                    onChanged: (v) async {
                      if (v) {
                        final granted =
                            await requestSmsPermissionWithGuidance(context);
                        if (!granted) return;
                      }
                      ref
                          .read(settingsRepositoryProvider)
                          .setSmsDetectionEnabled(v);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Bancos monitoreados'),
                    subtitle: const Text(
                        'Opcional: mejora la detección para un banco en particular'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SmsSendersScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _SectionTitle('Presupuesto'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Presupuesto mensual'),
                subtitle: Text(
                  settings.monthlyBudget == null
                      ? 'No configurado. Tócalo para definir uno.'
                      : 'Actualmente: ${Formatters.money(settings.monthlyBudget!)} al mes',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _editMonthlyBudget(context, ref, settings.monthlyBudget),
              ),
            ),
            const _SectionTitle('Tus datos'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded),
                    title: const Text('Exportar movimientos (CSV)'),
                    subtitle: const Text(
                        'Genera un respaldo de todos tus ingresos y gastos'),
                    onTap: () => _exportCsv(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.expense),
                    title: const Text('Borrar todos los datos',
                        style: TextStyle(color: AppColors.expense)),
                    subtitle: const Text(
                        'Elimina todos tus movimientos para empezar de cero'),
                    onTap: () => _confirmDeleteAll(context, ref),
                  ),
                ],
              ),
            ),
            const _SectionTitle('Acerca de'),
            const Card(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                title: Text('Contabilidad personal'),
                subtitle: Text('Versión 1.0.2 · 100% local, sin nube · COP'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _editMonthlyBudget(
      BuildContext context, WidgetRef ref, double? current) async {
    final controller = TextEditingController(
      text: current == null ? '' : current.toStringAsFixed(0),
    );
    final result = await showDialog<_BudgetDialogResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Presupuesto mensual'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: r'$ ',
            hintText: 'Ej. 2.000.000',
          ),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(_BudgetDialogResult.remove()),
              child: const Text('Quitar'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final amount =
                  double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', '.'));
              Navigator.of(dialogContext)
                  .pop(_BudgetDialogResult.save(amount));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final repo = ref.read(settingsRepositoryProvider);
    if (result.remove) {
      await repo.setMonthlyBudget(null);
    } else if (result.amount != null && result.amount! > 0) {
      await repo.setMonthlyBudget(result.amount);
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(transactionRepositoryProvider);
    final items = await repo.watchAll().first;

    final buffer = StringBuffer()
      ..writeln('Fecha,Hora,Tipo,Categoría,Monto,Descripción');
    for (final item in items) {
      final tx = item.transaction;
      final fecha = Formatters.fullDate.format(tx.date);
      final hora = Formatters.time.format(tx.date);
      final tipo = tx.type == TxType.income ? 'Ingreso' : 'Gasto';
      final categoria = _csvEscape(item.category.name);
      final monto = tx.amount.toStringAsFixed(0);
      final descripcion = _csvEscape(tx.description);
      buffer.writeln('$fecha,$hora,$tipo,$categoria,$monto,$descripcion');
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'movimientos.csv'));
    await file.writeAsString(buffer.toString());

    if (!context.mounted) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Respaldo de movimientos - Contabilidad personal',
    );
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar todos los datos?'),
        content: const Text(
          'Esto borrará todos tus ingresos y gastos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(transactionRepositoryProvider).deleteAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los movimientos fueron borrados')),
      );
    }
  }
}

class _BudgetDialogResult {
  final double? amount;
  final bool remove;
  _BudgetDialogResult.save(this.amount) : remove = false;
  _BudgetDialogResult.remove()
      : amount = null,
        remove = true;
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}
