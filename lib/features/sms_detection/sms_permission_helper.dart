import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pide el permiso de SMS y, si Android lo bloquea (algo normal para apps
/// instaladas fuera de Play Store desde Android 13), explica al usuario en
/// lenguaje simple cómo desbloquearlo manualmente, en vez de fallar en
/// silencio o mostrar un error técnico.
Future<bool> requestSmsPermissionWithGuidance(BuildContext context) async {
  final status = await Permission.sms.request();
  if (status.isGranted) return true;
  if (!context.mounted) return false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Activa el permiso manualmente'),
      content: const Text(
        'Por seguridad, Android bloquea este permiso para apps instaladas '
        'fuera de la Play Store, como esta. Para activarlo:\n\n'
        '1. Ve a Ajustes del celular → Apps → Bolsillo.\n'
        '2. Toca el menú ⋮ (arriba a la derecha).\n'
        '3. Toca "Permitir ajustes restringidos".\n'
        '4. Vuelve aquí e inténtalo de nuevo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Entendido'),
        ),
        FilledButton(
          onPressed: () {
            openAppSettings();
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Abrir ajustes'),
        ),
      ],
    ),
  );
  return false;
}
