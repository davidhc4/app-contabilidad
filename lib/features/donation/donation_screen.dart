import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/donation.dart';
import '../../core/utils/thousands_formatter.dart';

/// Pantalla para apoyar la app con una donación voluntaria.
class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _customController = TextEditingController();
  int? _preset;
  int _linkIndex = 0;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int? get _amount {
    final custom = parseThousands(_customController.text);
    return custom ?? _preset;
  }

  Future<void> _donate(DonationLink link) async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = _amount;
    if (link.usesAmount && (amount == null || amount <= 0)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Elige primero cuánto quieres donar')),
      );
      return;
    }
    final ok = await launchUrl(
      link.uriFor(amount),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la página de pago en tu navegador'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final links = kDonationLinks;
    final amount = _amount;
    final link = links.isEmpty ? null : links[_linkIndex.clamp(0, links.length - 1)];

    return Scaffold(
      appBar: AppBar(title: const Text('Apoyar Bolsillo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Icon(Icons.favorite_rounded, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            '¡Gracias por querer apoyar!',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Bolsillo es gratis, no tiene anuncios y no te pide ningún dato. '
            'Si te sirve y quieres ayudar a que siga mejorando, puedes donar '
            'el monto que quieras. Es totalmente voluntario y la app funciona '
            'igual si no donas.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cómo funciona',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text(
                    '1. Elige cuánto quieres donar.\n'
                    '2. Elige el método de pago.\n'
                    '3. Se abre la página segura del proveedor en tu '
                    'navegador, donde pones los datos de tu tarjeta o cuenta.\n\n'
                    'Bolsillo nunca ve ni guarda esos datos: el pago lo '
                    'procesa directamente el proveedor.',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (link == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Todavía no hay métodos de donación activos. Pronto los '
                  'agregaremos. ¡Gracias por la intención!',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            Text('¿Cuánto quieres donar?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final v in link.presets)
                  ChoiceChip(
                    label: Text('${link.currency} $v'),
                    selected: _preset == v && _customController.text.isEmpty,
                    onSelected: (_) => setState(() {
                      _preset = v;
                      _customController.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsInputFormatter()],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Otro monto',
                prefixText: '${link.currency} ',
              ),
            ),
            const SizedBox(height: 20),
            Text('Método de pago', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (var i = 0; i < links.length; i++)
              Card(
                child: ListTile(
                  leading: Icon(_linkIndex == i
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded),
                  title: Text(links[i].name),
                  subtitle: Text(links[i].description),
                  onTap: () => setState(() {
                    _linkIndex = i;
                    _preset = null;
                    _customController.clear();
                  }),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _donate(link),
              icon: const Icon(Icons.favorite_rounded),
              label: Text(amount == null || amount <= 0
                  ? 'Donar'
                  : 'Donar ${link.currency} $amount'),
            ),
          ],
        ],
      ),
    );
  }
}
