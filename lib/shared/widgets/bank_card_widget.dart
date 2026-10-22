import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/icon_map.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../features/cards/account_balances.dart';
import '../../features/cards/card_style.dart';
import '../../core/utils/formatters.dart';

/// Tarjeta visual de una tarjeta guardada: toma la foto/sticker que el
/// usuario eligió para ella (si hay).
class BankCardWidget extends ConsumerWidget {
  final CardItem card;
  final double aspectRatio;

  const BankCardWidget({super.key, required this.card, this.aspectRatio = 1.6});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(cardStylesProvider)[card.id] ?? CardStyle.empty;
    final movements = ref.watch(accountMovementsProvider);
    return BankCardView(
      balance: cardBalance(card.id, movements, {card.id: style}),
      name: card.name,
      lastFourDigits: card.lastFourDigits,
      network: card.network,
      colorStart: card.colorStart,
      colorEnd: card.colorEnd,
      style: style,
      aspectRatio: aspectRatio,
    );
  }
}

/// Dibujo de la tarjeta a partir de datos sueltos (sirve también para la
/// vista previa mientras se crea o edita una tarjeta).
///
/// Estilo Lemon/Nu: gradiente de color, nombre, últimos 4 dígitos y red.
/// No representa ninguna conexión bancaria real.
class BankCardView extends StatelessWidget {
  final String name;
  final String lastFourDigits;
  final String network;
  final String colorStart;
  final String colorEnd;
  final CardStyle style;
  final double aspectRatio;

  /// Saldo a mostrar en la tarjeta (null = no mostrar).
  final double? balance;

  const BankCardView({
    super.key,
    required this.name,
    required this.lastFourDigits,
    required this.network,
    required this.colorStart,
    required this.colorEnd,
    this.style = CardStyle.empty,
    this.aspectRatio = 1.6,
    this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final photoPath = style.photoPath;
    final hasPhoto = photoPath != null && File(photoPath).existsSync();

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorFromHex(colorStart), colorFromHex(colorEnd)],
          ),
          boxShadow: [
            BoxShadow(
              color: colorFromHex(colorEnd).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto) ...[
                Image.file(
                  File(photoPath),
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                // Capa oscura para que el texto blanco siga leyéndose.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0x99000000)],
                    ),
                  ),
                ),
              ],
              if (style.sticker != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: _Sticker(emoji: style.sticker!),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.wifi_rounded,
                            color: Colors.white70, size: 22),
                      ],
                    ),
                    if (balance != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saldo',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                          Text(
                            Formatters.money(balance!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '•• •• •• $lastFourDigits',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _NetworkBadge(network: network),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticker: el emoji dentro de una "pegatina" blanca ligeramente girada.
class _Sticker extends StatelessWidget {
  final String emoji;
  const _Sticker({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 44, height: 1.1)),
      ),
    );
  }
}

class _NetworkBadge extends StatelessWidget {
  final String network;
  const _NetworkBadge({required this.network});

  @override
  Widget build(BuildContext context) {
    final label = switch (network) {
      CardNetwork.visa => 'VISA',
      CardNetwork.mastercard => 'Mastercard',
      _ => 'Tarjeta',
    };
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        fontSize: 16,
      ),
    );
  }
}
