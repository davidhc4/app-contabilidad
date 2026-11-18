import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/donation.dart';
import '../../core/utils/thousands_formatter.dart';

/// Pantalla para apoyar la app con una donación voluntaria. Tiene dos modos:
/// PayPal (con tarjeta/saldo) y Nequi/QR (cualquier banco colombiano).
class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _customController = TextEditingController();
  int? _preset;
  int _mode = 0; // 0 = Nequi/QR, 1 = PayPal

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

  Future<void> _copyNumber() async {
    await Clipboard.setData(const ClipboardData(text: kNequiNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número copiado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Si te sirve y quieres ayudar a que siga mejorando, puedes apoyar '
            'con el monto que quieras. Es voluntario y la app funciona igual '
            'si no lo haces.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Nequi / QR')),
              ButtonSegment(value: 1, label: Text('PayPal')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 20),
          if (_mode == 0) _buildNequi(theme) else _buildPaypal(theme),
          const SizedBox(height: 20),
          Text(
            'El pago lo procesa directamente el proveedor (tu banco, Nequi o '
            'PayPal). Bolsillo nunca ve ni guarda los datos de tu tarjeta o '
            'cuenta.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNequi(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Escanea el QR desde Nequi o la app de cualquier banco '
              'colombiano.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                kNequiQrAsset,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(kNequiName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('Nequi', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            Text('O transfiere a este número',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(
                  kNequiNumber,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: _copyNumber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaypal(ThemeData theme) {
    final link = kDonationLinks.isEmpty ? null : kDonationLinks.first;
    if (link == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('PayPal no está disponible por ahora.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }
    final amount = _amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Con tarjeta o saldo de PayPal (en dólares).',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
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
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _donate(link),
          icon: const Icon(Icons.favorite_rounded),
          label: Text(amount == null || amount <= 0
              ? 'Donar con PayPal'
              : 'Donar ${link.currency} $amount'),
        ),
      ],
    );
  }
}
