import 'package:flutter/material.dart';

import '../../core/utils/icon_map.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';

/// Tarjeta visual estilo Lemon/Nu: gradiente de color elegido por el
/// usuario, nombre, últimos 4 dígitos enmascarados y el logo/texto de la
/// red (Visa/Mastercard/Otra). No representa ninguna conexión bancaria
/// real, es solo un dato que el usuario crea manualmente.
class BankCardWidget extends StatelessWidget {
  final CardItem card;
  final double aspectRatio;

  const BankCardWidget({super.key, required this.card, this.aspectRatio = 1.6});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorFromHex(card.colorStart),
              colorFromHex(card.colorEnd),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorFromHex(card.colorEnd).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Icon(Icons.wifi_rounded, color: Colors.white70, size: 22),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '•• •• •• ${card.lastFourDigits}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _NetworkBadge(network: card.network),
              ],
            ),
          ],
        ),
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
