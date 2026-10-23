import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_version.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/progress_dialog.dart';
import '../budget/budget_dialog.dart';
import '../data_export/export_data.dart';
import '../data_export/import_data.dart';
import '../help/tutorial_screen.dart';
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
                      ? 'No configurado. Es el dinero con el que cuentas cada mes; '
                          'tócalo para definirlo.'
                      : 'Presupuesto: ${Formatters.money(settings.monthlyBudget!)} al mes. '
                          'Los gastos se descuentan de este monto y lo que '
                          'sobra es lo que puedes ahorrar (mira Resumen).',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showBudgetDialog(context, ref, settings.monthlyBudget),
              ),
            ),
            const _SectionTitle('Tus datos'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded),
                    title: const Text('Compartir copia en CSV'),
                    subtitle: const Text(
                        'Crea un archivo CSV (se abre en Excel) y te deja '
                        'mandarlo por correo, Drive, OneDrive, WhatsApp u '
                        'otra app. Tus datos salen solo cuando tú lo decides.'),
                    onTap: () => _shareCsv(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: const Text('Importar copia CSV'),
                    subtitle: const Text(
                        'Recupera tus movimientos desde un archivo que '
                        'guardaste con "Compartir copia en CSV". No duplica '
                        'lo que ya tengas.'),
                    onTap: () => _importCsv(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.expense),
                    title: const Text('Borrar todos los datos',
                        style: TextStyle(color: AppColors.expense)),
                    subtitle: const Text(
                        'Elimina todos tus movimientos. No se puede '
                        'deshacer: antes de borrar, guarda una copia.'),
                    onTap: () => _confirmDeleteAll(context, ref),
                  ),
                ],
              ),
            ),
            const _SectionTitle('Ayuda'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Cómo usar la app'),
                subtitle: const Text(
                    'Mini tutorial: qué hace cada sección y cada botón'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TutorialScreen(),
                  ),
                ),
              ),
            ),
            const _SectionTitle('Acerca de'),
            const Card(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                title: Text(kAppName),
                subtitle: Text('Versión $kAppVersion'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _shareCsv(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await runWithProgress(
        context,
        'Creando el archivo CSV…',
        () => createCsvFile(ref),
      );
      if (result.count == 0) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Aún no tienes movimientos para exportar')),
        );
        return;
      }
      await shareCsvFile(result.file);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo crear el CSV: $e')));
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;
    try {
      final result = await runWithProgress(
        context,
        'Importando tus movimientos…',
        () => importCsvFile(ref, File(path)),
      );
      final extra = [
        if (result.newCards > 0) '${result.newCards} tarjeta(s) nueva(s)',
        if (result.newCategories > 0)
          '${result.newCategories} categoría(s) nueva(s)',
      ].join(', ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Listo: ${result.added} movimientos importados'
            '${result.skipped > 0 ? ', ${result.skipped} omitidos (ya estaban o no se pudieron leer)' : ''}'
            '${extra.isEmpty ? '' : '. Se crearon $extra'}.',
          ),
        ),
      );
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo importar: $e')));
    }
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

    if (confirmed != true || !context.mounted) return;
    await runWithProgress(
      context,
      'Borrando tus movimientos…',
      () => ref.read(transactionRepositoryProvider).deleteAll(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los movimientos fueron borrados')),
      );
    }
  }
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
