import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rewards_state.dart';
import 'skins.dart';

const _tile = 104.0;
const _winIndex = 38;

/// Recompensas: cuanto más tiempo pasas en la app, más cajas ganas. Cada
/// caja da un aspecto al azar para tus tarjetas.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final _controller = ScrollController();
  final _rng = math.Random();
  late List<Skin> _strip = List.generate(30, (_) => pickSkin(_rng));
  bool _spinning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _available(int seconds, int opened) =>
      seconds ~/ kSecondsPerBox - opened;

  Future<void> _open() async {
    if (_spinning) return;
    final seconds = ref.read(usageProvider);
    final rewards = ref.read(rewardsProvider);
    if (_available(seconds, rewards.boxesOpened) <= 0) return;

    setState(() => _spinning = true);
    await ref.read(rewardsProvider.notifier).useBox();
    final winner = pickSkin(_rng);
    setState(() {
      _strip = List.generate(
        46,
        (i) => i == _winIndex ? winner : pickSkin(_rng),
      );
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (_controller.hasClients) {
      _controller.jumpTo(0);
      final viewport = _controller.position.viewportDimension;
      final target = _winIndex * _tile +
          _tile / 2 -
          viewport / 2 +
          (_rng.nextDouble() - 0.5) * _tile * 0.6;
      await _controller.animateTo(
        target,
        duration: const Duration(seconds: 5),
        curve: Curves.easeOutQuart,
      );
    }
    final isNew = await ref.read(rewardsProvider.notifier).grant(winner.id);
    if (!mounted) return;
    setState(() => _spinning = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¡Te salió!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SkinTile(skin: winner, width: 140),
            const SizedBox(height: 12),
            Text(
              isNew
                  ? 'Nuevo aspecto para tus tarjetas. Lo eliges al '
                      'personalizar una tarjeta.'
                  : 'Ya lo tenías. La próxima caja puede traer algo distinto.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Genial'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = ref.watch(usageProvider);
    final rewards = ref.watch(rewardsProvider);
    final available = _available(seconds, rewards.boxesOpened);
    final intoBox = (seconds % kSecondsPerBox) / kSecondsPerBox;
    final minutes = seconds ~/ 60;
    final owned = [
      for (final s in kSkins)
        if (rewards.owned.contains(s.id)) s,
      for (final s in kExtraSkins)
        if (rewards.owned.contains(s.id)) s,
    ];
    final rarities = <Rarity>[
      for (final r in Rarity.values)
        if (r.weight > 0) r,
    ];
    final totalWeight = rarities.fold<double>(0, (a, r) => a + r.weight);

    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiempo en la app: $minutes min',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Cada 10 minutos dentro de la app ganas una caja con un '
                    'aspecto para tus tarjetas. Los minutos se acumulan, '
                    'aunque entres solo un momento.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: intoBox, minHeight: 10),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    available > 0
                        ? 'Cajas disponibles: $available'
                        : 'Te falta ${((1 - intoBox) * kSecondsPerBox / 60).ceil()} min para la próxima caja',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListView.builder(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemExtent: _tile,
                  itemCount: _strip.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: _SkinTile(skin: _strip[i], width: _tile - 8),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    width: 3,
                    height: 128,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: (_spinning || available <= 0) ? null : _open,
            icon: const Icon(Icons.inventory_2_rounded),
            label: Text(_spinning ? 'Abriendo…' : 'Abrir caja'),
          ),
          const SizedBox(height: 20),
          Text('Probabilidades', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final r in rarities)
                Chip(
                  label: Text(
                    '${r.label} ${(r.weight / totalWeight * 100).toStringAsFixed(r.weight < 1 ? 1 : 0)}%',
                    style: TextStyle(
                      color: r.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Tus aspectos (${owned.length})',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in owned) _SkinTile(skin: s, width: 100),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  final Skin skin;
  final double width;
  const _SkinTile({required this.skin, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: skin.rarity.color, width: 2),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: skin.image ? Colors.black : null,
              gradient: skin.image
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [skin.a, skin.b],
                    ),
            ),
            child: skin.image
                ? const Center(
                    child: Icon(Icons.image_rounded, color: Colors.white70),
                  )
                : null,
          ),
          const SizedBox(height: 4),
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
    );
  }
}
