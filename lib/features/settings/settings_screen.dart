import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            const _SectionTitle('Acerca de'),
            const Card(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                title: Text('Contabilidad personal'),
                subtitle: Text('Versión 1.0.0 · 100% local, sin nube'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
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
