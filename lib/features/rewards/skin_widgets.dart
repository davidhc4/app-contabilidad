import 'package:flutter/material.dart';

import '../../data/local/tables.dart';
import '../../shared/widgets/bank_card_widget.dart';
import '../cards/card_style.dart';
import 'rewards_state.dart';
import 'skins.dart';

/// Vista previa de un aspecto: una tarjeta pequeña con el efecto puesto.
class SkinPreview extends StatelessWidget {
  final Skin skin;
  final double width;
  final bool animate;

  const SkinPreview({
    super.key,
    required this.skin,
    required this.width,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width / 1.6,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          child: BankCardView(
            name: 'Mi tarjeta',
            lastFourDigits: '1234',
            network: CardNetwork.visa,
            colorStart: kCardStart,
            colorEnd: kCardEnd,
            style: CardStyle(skin: skin.id),
            animate: animate,
          ),
        ),
      ),
    );
  }
}

/// Casilla con la vista previa, el nombre y la rareza de un aspecto.
class SkinTile extends StatelessWidget {
  final Skin skin;
  final double width;
  final bool owned;
  final bool animate;
  final VoidCallback? onTap;

  const SkinTile({
    super.key,
    required this.skin,
    required this.width,
    this.owned = true,
    this.animate = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: skin.rarity.color, width: 2),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: owned ? 1 : 0.45,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SkinPreview(skin: skin, width: width - 16, animate: animate),
                  if (!owned)
                    const Icon(Icons.lock_rounded, color: Colors.white70, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              skin.rarity.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: skin.rarity.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatSeconds(int seconds) {
  if (seconds < 60) return '$seconds s';
  final m = seconds ~/ 60;
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${m % 60} min';
}

/// Ventana con el detalle de un aspecto y cuánto se ha usado.
Future<void> showSkinDetails(
  BuildContext context,
  Skin skin, {
  required bool owned,
  SkinStat? stat,
  int? serial,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(skin.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: SkinPreview(skin: skin, width: 260)),
          const SizedBox(height: 12),
          Text(
            '${skin.family.label} · ${skin.rarity.label}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: skin.rarity.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(skin.family.description),
          const SizedBox(height: 10),
          if (serial != null) ...[
            Text('Aspecto único Nº $serial',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
          ],
          if (!owned)
            Text(skin.special
                ? 'Es un aspecto único: solo se consigue con un código del '
                    'creador de la app.'
                : 'Aún no lo tienes. Sale al abrir cajas.')
          else if (stat == null || stat.uses == 0)
            const Text('Todavía no lo has usado en ninguna tarjeta.')
          else
            Text(
              'Lo has puesto ${stat.uses} ${stat.uses == 1 ? 'vez' : 'veces'} '
              'y ha estado a la vista ${formatSeconds(stat.seconds)}.',
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
