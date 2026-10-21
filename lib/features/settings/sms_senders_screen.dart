import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class SmsSendersScreen extends ConsumerWidget {
  const SmsSendersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendersAsync = ref.watch(smsSenderRepositoryProvider).watchAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Bancos monitoreados')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSenderDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder(
        stream: sendersAsync,
        builder: (context, snapshot) {
          final senders = snapshot.data ?? [];
          if (senders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Agrega el nombre o número del remitente de tu banco y, '
                  'opcionalmente, un patrón (regex) para extraer el monto '
                  'de sus SMS.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: senders.length,
            itemBuilder: (context, i) {
              final s = senders[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: SwitchListTile(
                  title: Text(s.senderIdOrName),
                  subtitle: Text(
                    s.regexPattern,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: s.isEnabled,
                  onChanged: (v) => ref
                      .read(smsSenderRepositoryProvider)
                      .setEnabled(s.id, v),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSenderDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final regexController = TextEditingController(
      text: r'(?:\$|COP)?\s*([0-9.,]+)',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo remitente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre o número del remitente',
                hintText: 'Ej. BancoX, 85055',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: regexController,
              decoration: const InputDecoration(
                labelText: 'Patrón para extraer el monto (regex)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              ref.read(smsSenderRepositoryProvider).add(
                    senderIdOrName: nameController.text.trim(),
                    regexPattern: regexController.text.trim(),
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
