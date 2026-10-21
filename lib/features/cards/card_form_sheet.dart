import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/icon_map.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';

/// Crear una tarjeta nueva (dato 100% local, el usuario la crea a mano).
Future<void> showCardFormSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const CardFormSheet(),
  );
}

/// Paleta de gradientes predefinidos para elegir, al estilo de la paleta de
/// colores de categorías.
const _gradients = <List<String>>[
  ['FF0A84FF', 'FF64D2FF'], // azul
  ['FF30D158', 'FF63E6E2'], // verde
  ['FFBF5AF2', 'FFFF375F'], // morado-rosa
  ['FFFF9F0A', 'FFFF453A'], // naranja-rojo
  ['FF1C1C1E', 'FF636366'], // negro/gris (estilo Nu)
  ['FFFFD60A', 'FF30D158'], // amarillo-verde (estilo Lemon)
];

class CardFormSheet extends ConsumerStatefulWidget {
  const CardFormSheet({super.key});

  @override
  ConsumerState<CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends ConsumerState<CardFormSheet> {
  final _nameController = TextEditingController();
  final _digitsController = TextEditingController();
  String _network = CardNetwork.visa;
  List<String> _gradient = _gradients.first;

  @override
  void dispose() {
    _nameController.dispose();
    _digitsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final digits = _digitsController.text.trim();
    if (name.isEmpty || digits.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el nombre y los 4 últimos dígitos'),
        ),
      );
      return;
    }
    await ref.read(cardRepositoryProvider).addCard(
          name: name,
          lastFourDigits: digits,
          network: _network,
          colorStart: _gradient[0],
          colorEnd: _gradient[1],
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nueva tarjeta',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'Nombre, ej. Nu Mastercard'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _digitsController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Últimos 4 dígitos',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          Text('Red', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: CardNetwork.visa, label: Text('Visa')),
              ButtonSegment(
                  value: CardNetwork.mastercard, label: Text('Mastercard')),
              ButtonSegment(value: CardNetwork.other, label: Text('Otra')),
            ],
            selected: {_network},
            onSelectionChanged: (s) => setState(() => _network = s.first),
          ),
          const SizedBox(height: 16),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _gradients.map((g) {
              final selected = g == _gradient;
              return GestureDetector(
                onTap: () => setState(() => _gradient = g),
                child: Container(
                  width: 44,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colorFromHex(g[0]), colorFromHex(g[1])],
                    ),
                    border: selected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _submit, child: const Text('Crear')),
        ],
      ),
    );
  }
}
