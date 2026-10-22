import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';
import '../budget/budget_dialog.dart';
import '../drive_sync/drive_sync_service.dart';
import '../drive_sync/drive_sync_ui.dart';
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
                      ? 'No configurado. Tócalo para definir cuánto planeas gastar al mes.'
                      : 'Tope de gasto: ${Formatters.money(settings.monthlyBudget!)} al mes. '
                          'Cada gasto que registres se resta de este monto; '
                          'míralo en la pestaña Resumen.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showBudgetDialog(context, ref, settings.monthlyBudget),
              ),
            ),
            const _SectionTitle('Acceso rápido'),
            const Card(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                leading: Icon(Icons.bolt_rounded),
                title: Text('Registrar desde el panel de tu celular'),
                subtitle: Text(
                  'Desliza hacia abajo desde arriba de la pantalla, abre '
                  '"Editar y ordenar" y agrega los botones "Agregar gasto" '
                  'y "Agregar ingreso". Así registras un movimiento sin '
                  'abrir la app.',
                ),
              ),
            ),
            const _SectionTitle('Tus datos'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: const Text('Enviar datos a Google Drive'),
                    subtitle: const Text(
                        'Sube todos tus ingresos y gastos a la hoja '
                        '"Finanzas App" de la carpeta FINANZAS de tu Drive'),
                    onTap: () => syncToDrive(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.link_rounded),
                    title: const Text('Conexión con Google Drive'),
                    subtitle: const Text(
                        'Pega la dirección de tu script y la clave'),
                    onTap: () async {
                      final current = await DriveSyncConfig.load();
                      if (!context.mounted) return;
                      await showDriveConfigDialog(context, current);
                    },
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
