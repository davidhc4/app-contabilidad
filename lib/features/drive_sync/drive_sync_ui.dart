import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import 'drive_sync_service.dart';

/// Envía todos los movimientos a la hoja de la carpeta FINANZAS de Google
/// Drive. Si todavía no hay conexión configurada, la pide primero.
Future<void> syncToDrive(BuildContext context, WidgetRef ref) async {
  var config = await DriveSyncConfig.load();
  if (config == null) {
    if (!context.mounted) return;
    config = await showDriveConfigDialog(context, null);
    if (config == null) return;
  }
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Enviando datos a Google Drive…'),
      duration: Duration(seconds: 30),
    ),
  );

  try {
    final items = await ref.read(transactionRepositoryProvider).watchAll().first;
    final cards = await ref.read(cardRepositoryProvider).watchAll().first;
    final cardNames = {
      for (final c in cards) c.id: '${c.name} •••• ${c.lastFourDigits}',
    };
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    // Orden cronológico: lo más antiguo primero.
    final rows = <List<Object>>[
      for (final item in items.reversed)
        [
          dateFormat.format(item.transaction.date),
          timeFormat.format(item.transaction.date),
          item.transaction.type == TxType.income ? 'Ingreso' : 'Gasto',
          item.category.name,
          item.transaction.amount.round(),
          item.transaction.description,
          cardNames[item.transaction.cardId] ?? '',
          item.transaction.source == TxSource.sms ? 'SMS' : 'Manual',
          item.transaction.id,
        ],
    ];

    final count = await sendRowsToDrive(config, rows);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Listo: $count movimientos enviados a Google Drive'),
      ),
    );
  } on DriveSyncException catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
  }
}

/// Pide (o edita) la dirección del script y la clave. Devuelve la
/// configuración guardada, o null si se cancela.
Future<DriveSyncConfig?> showDriveConfigDialog(
  BuildContext context,
  DriveSyncConfig? current,
) async {
  final urlController = TextEditingController(text: current?.url ?? '');
  final tokenController = TextEditingController(text: current?.token ?? '');
  String? error;

  final result = await showDialog<DriveSyncConfig>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Conectar con Google Drive'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pega aquí la dirección de tu script de Google (la que '
                'empieza con https://script.google.com/) y la clave que '
                'pusiste en el script. Los datos se guardarán en la '
                'carpeta FINANZAS de tu Drive.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Dirección del script',
                  hintText: 'https://script.google.com/macros/s/…/exec',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: 'Clave'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () async {
                await DriveSyncConfig.clear();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Desconectar'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final url = urlController.text.trim();
              final token = tokenController.text.trim();
              if (!DriveSyncConfig.isValidUrl(url)) {
                setState(() => error =
                    'La dirección debe empezar con https://script.google.com/');
                return;
              }
              if (token.isEmpty) {
                setState(() => error = 'Escribe la clave');
                return;
              }
              final config = DriveSyncConfig(url: url, token: token);
              await config.save();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(config);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  urlController.dispose();
  tokenController.dispose();
  return result;
}
