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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSenderSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar banco'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'La detección de pagos ya funciona automáticamente para la '
              'mayoría de bancos, sin necesidad de configurar nada aquí. '
              'Solo agrega un banco si notas que algunos de sus SMS no se '
              'detectan bien.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: sendersAsync,
              builder: (context, snapshot) {
                final senders = snapshot.data ?? [];
                if (senders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_outlined,
                              size: 40,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 12),
                          const Text(
                            'Todavía no agregaste ningún banco específico',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: senders.length,
                  itemBuilder: (context, i) {
                    final s = senders[i];
                    final isCustom = s.regexPattern.trim().isNotEmpty;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: SwitchListTile(
                        title: Text(s.senderIdOrName),
                        subtitle: Text(
                          isCustom
                              ? 'Detección personalizada'
                              : 'Detección automática',
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => ref
                              .read(smsSenderRepositoryProvider)
                              .delete(s.id),
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
          ),
        ],
      ),
    );
  }

  void _showAddSenderSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final regexController = TextEditingController();
    var showAdvanced = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Agregar banco',
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Escribe el nombre con el que te llegan los SMS de tu '
                'banco (por ejemplo "Bancolombia" o "Nequi"), tal como '
                'aparece como remitente del mensaje.',
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(sheetContext).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre del banco o remitente',
                  hintText: 'Ej. Bancolombia',
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    setSheetState(() => showAdvanced = !showAdvanced),
                icon: Icon(showAdvanced
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded),
                label: const Text('Opciones avanzadas (opcional)'),
              ),
              if (showAdvanced) ...[
                const SizedBox(height: 4),
                Text(
                  'Solo complétalo si los montos de este banco no se '
                  'detectan correctamente. Déjalo vacío para usar la '
                  'detección automática normal.',
                  style:
                      Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                            color: Theme.of(sheetContext).colorScheme.outline,
                          ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: regexController,
                  decoration: const InputDecoration(
                    labelText: 'Patrón de búsqueda personalizado',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  ref.read(smsSenderRepositoryProvider).add(
                        senderIdOrName: nameController.text.trim(),
                        regexPattern: regexController.text.trim(),
                      );
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
