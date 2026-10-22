import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pide permiso para acceder a las fotos del celular (el mismo cuadro del
/// sistema que se ve con la ubicación). Sin este permiso no se puede elegir
/// una foto. Devuelve `true` si ya se puede usar la galería.
Future<bool> ensureGalleryPermission(BuildContext context) async {
  var status = await Permission.photos.status;
  if (status.isGranted || status.isLimited) return true;

  status = await Permission.photos.request();
  if (status.isGranted || status.isLimited) return true;
  if (!context.mounted) return false;

  if (status.isPermanentlyDenied) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permiso de fotos desactivado'),
        content: const Text(
          'Para poner una foto en tus tarjetas, la app necesita acceso a tus '
          'fotos. Actívalo en Ajustes del celular → Apps → esta app → '
          'Permisos → Fotos y videos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ahora no'),
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
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sin el permiso de fotos no se puede elegir una imagen'),
      ),
    );
  }
  return false;
}
