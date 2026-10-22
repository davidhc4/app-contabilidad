import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../providers/app_providers.dart';
import 'account_balances.dart';
import 'card_style.dart';

/// Abre el formulario para mover dinero de una tarjeta/cuenta a otra.
Future<void> showTransferSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const TransferSheet(),
  );
}

const _cashId = '_efectivo';

class _Account {
  final String id; // _cashId para "Efectivo / sin tarjeta"
  final String label;
  final double balance;
  final IconData icon;
  const _Account(this.id, this.label, this.balance, this.icon);

  String? get cardId => id == _cashId ? null : id;
}

class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _from;
  String? _to;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  _Account? _find(List<_Account> accounts, String? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<_Account?> _pick({
    required String title,
    required List<_Account> accounts,
    required bool requireMoney,
    String? exclude,
  }) {
    final options = accounts.where((a) => a.id != exclude).toList();
    return showModalBottomSheet<_Account>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                for (final a in options)
                  ListTile(
                    enabled: !requireMoney || a.balance > 0,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(a.icon,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(a.label),
                    subtitle: requireMoney && a.balance <= 0
                        ? const Text('No tiene dinero para mover')
                        : null,
                    trailing: Text(
                      Formatters.money(a.balance),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => Navigator.of(ctx).pop(a),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(List<_Account> accounts) async {
    final amount = parseThousands(_amountController.text)?.toDouble();
    final messenger = ScaffoldMessenger.of(context);
    void warn(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));

    final from = _find(accounts, _from);
    final to = _find(accounts, _to);
    if (from == null || to == null) {
      warn('Elige de dónde sale y a dónde llega el dinero');
      return;
    }
    if (from.id == to.id) {
      warn('El origen y el destino deben ser distintos');
      return;
    }
    if (amount == null || amount <= 0) {
      warn('Escribe el monto a transferir');
      return;
    }
    if (amount > from.balance) {
      warn('${from.label} solo tiene ${Formatters.money(from.balance)}. '
          'No puedes mover más de lo que hay.');
      return;
    }

    final note = _noteController.text.trim();
    final description =
        note.isEmpty ? 'Transferencia de ${from.label} a ${to.label}' : note;

    setState(() => _saving = true);
    try {
      await ref.read(transactionRepositoryProvider).addTransfer(
            fromCardId: from.cardId,
            toCardId: to.cardId,
            amount: amount,
            date: DateTime.now(),
            description: description,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      warn('Listo: ${Formatters.money(amount)} de ${from.label} a ${to.label}');
    } catch (e) {
      warn('No se pudo transferir: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = ref.watch(cardsProvider).valueOrNull ?? const [];
    final styles = ref.watch(cardStylesProvider);
    final movements = ref.watch(accountMovementsProvider);

    final accounts = <_Account>[
      _Account(_cashId, 'Efectivo / sin tarjeta',
          cardBalance(null, movements, styles), Icons.payments_rounded),
      for (final c in cards)
        _Account(
          c.id,
          '${c.name} ••${c.lastFourDigits}',
          cardBalance(c.id, movements, styles),
          Icons.credit_card_rounded,
        ),
    ];

    final from = _find(accounts, _from);
    final to = _find(accounts, _to);
    final hasMoney = accounts.any((a) => a.balance > 0);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Transferir entre tarjetas',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Solo se puede mover el dinero que ya registraste (ingresos o '
              '"dinero que ya tiene" de la tarjeta). No cuenta como ingreso '
              'ni como gasto.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            if (!hasMoney)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Todavía no hay dinero para mover. Primero registra un '
                  'ingreso (o ponle "dinero que ya tiene" a una tarjeta).',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _AccountBox(
                      caption: 'Sale de',
                      account: from,
                      onTap: () async {
                        final picked = await _pick(
                          title: '¿De dónde sale el dinero?',
                          accounts: accounts,
                          requireMoney: true,
                        );
                        if (picked == null) return;
                        setState(() {
                          _from = picked.id;
                          if (_to == picked.id) _to = null;
                        });
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded),
                  ),
                  Expanded(
                    child: _AccountBox(
                      caption: 'Llega a',
                      account: to,
                      onTap: () async {
                        final picked = await _pick(
                          title: '¿A dónde llega el dinero?',
                          accounts: accounts,
                          requireMoney: false,
                          exclude: _from,
                        );
                        if (picked == null) return;
                        setState(() => _to = picked.id);
                      },
                    ),
                  ),
                ],
              ),
              if (from != null) ...[
                const SizedBox(height: 8),
                Text('Disponible en ${from.label}: '
                    '${Formatters.money(from.balance)}'),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsInputFormatter()],
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                decoration:
                    const InputDecoration(prefixText: r'$ ', hintText: '0'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Nota (opcional), ej. Pasé ahorros a Nequi',
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: (_saving || !hasMoney) ? null : () => _submit(accounts),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transferir'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuadro grande para elegir una cuenta (origen o destino).
class _AccountBox extends StatelessWidget {
  final String caption;
  final _Account? account;
  final VoidCallback onTap;
  const _AccountBox({
    required this.caption,
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acc = account;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            children: [
              Text(caption, style: theme.textTheme.labelMedium),
              const SizedBox(height: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  acc?.icon ?? Icons.add_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                acc?.label ?? 'Elegir',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
