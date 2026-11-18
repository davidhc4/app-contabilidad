import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_detection.dart';

/// Tarjeta de Ajustes para activar la detección de pagos por notificaciones.
class PaymentDetectionCard extends ConsumerStatefulWidget {
  const PaymentDetectionCard({super.key});

  @override
  ConsumerState<PaymentDetectionCard> createState() =>
      _PaymentDetectionCardState();
}

class _PaymentDetectionCardState extends ConsumerState<PaymentDetectionCard>
    with WidgetsBindingObserver {
  bool? _access;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await notifAccessGranted();
    if (mounted) setState(() => _access = granted);
  }

  Future<void> _explainAndOpen() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dar acceso a las notificaciones'),
        content: const Text(
          'Para detectar tus pagos, Android necesita que le permitas a '
          'Bolsillo leer las notificaciones. En la pantalla que se abre, '
          'busca "Bolsillo" y actívalo.\n\n'
          'La app solo mira las notificaciones que parecen un pago, todo en '
          'tu teléfono. No lee tu correo ni envía nada a internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
    if (go == true) await openNotifAccessSettings();
  }

  Future<void> _onToggle(bool value) async {
    await ref.read(notifEnabledProvider.notifier).set(value);
    if (value && _access == false) await _explainAndOpen();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(notifEnabledProvider);
    final needsAccess = enabled && _access == false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SwitchListTile(
            value: enabled,
            onChanged: _onToggle,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Detectar pagos por notificaciones'),
            subtitle: const Text(
              'Cuando tu banco o billetera te avise de un pago, la app te '
              'pregunta si quieres anotarlo. Todo en tu teléfono: no lee tu '
              'correo ni envía nada.',
            ),
            isThreeLine: true,
          ),
          if (needsAccess) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Falta dar acceso a las notificaciones'),
              subtitle: const Text('Tócalo para activarlo en Android.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _explainAndOpen,
            ),
          ],
        ],
      ),
    );
  }
}
