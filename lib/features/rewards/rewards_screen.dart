import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rewards_state.dart';
import 'skin_widgets.dart';
import 'skins.dart';

const _tile = 104.0;
const _winIndex = 38;

/// Recompensas: cuanto más tiempo pasas en la app, más cajas ganas. Las cajas
/// se acumulan y cada una da un aspecto al azar para tus tarjetas.
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
  String _previewColor = 'azul';
  int _lastTick = -1;
  double _flash = 0;
  Color _flashColor = Colors.white;

  /// Un "clic" (sonido y vibración) cada vez que una casilla pasa por la
  /// línea, como en las cajas de los juegos.
  void _onScroll() {
    if (!_spinning || !_controller.hasClients) return;
    final index =
        ((_controller.offset + _controller.position.viewportDimension / 2) /
                _tile)
            .floor();
    if (index != _lastTick) {
      _lastTick = index;
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    }
  }

  Duration _spinTime(Rarity r) => switch (r) {
        Rarity.comun || Rarity.pocoComun => const Duration(seconds: 5),
        Rarity.raro => const Duration(milliseconds: 6200),
        Rarity.epico => const Duration(seconds: 7),
        _ => const Duration(seconds: 9),
      };

  /// Destello de pantalla y vibración según la rareza del premio.
  Future<void> _finale(Rarity r) async {
    if (r == Rarity.comun || r == Rarity.pocoComun) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() {
      _flashColor = r.color;
      _flash = 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) setState(() => _flash = 0);
    final hits = switch (r) {
      Rarity.raro => 1,
      Rarity.epico => 2,
      _ => 5,
    };
    for (var i = 0; i < hits; i++) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(rewardsProvider.notifier).markAllSeen();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_spinning) return;
    if (ref.read(availableBoxesProvider) <= 0) return;

    _lastTick = -1;
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
        duration: _spinTime(winner.rarity),
        curve: Curves.easeOutQuart,
      );
    }
    final isNew =
        await ref.read(rewardsProvider.notifier).grant(winner.id, announce: false);
    if (isNew) await ref.read(rewardsProvider.notifier).markAllSeen();
    if (!mounted) return;
    setState(() => _spinning = false);
    await _finale(winner.rarity);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¡Te salió!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: winner.rarity.color.withValues(
                          alpha: 0.25 + 0.5 * winner.rarity.intensity,
                        ),
                        blurRadius: 12 + 34 * winner.rarity.intensity,
                        spreadRadius: 2 + 6 * winner.rarity.intensity,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
              child: SkinPreview(skin: winner, width: 240),
            ),
            const SizedBox(height: 14),
            Text(
              winner.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              '${winner.family.label} · ${winner.rarity.label}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: winner.rarity.color,
              ),
            ),
            const SizedBox(height: 10),
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

  String _clock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ref.watch(boxProgressProvider);
    final seconds = ref.watch(usageProvider);
    final available = ref.watch(availableBoxesProvider);
    final rewards = ref.watch(rewardsProvider);
    final stats = ref.watch(skinStatsProvider);
    final owned = [
      for (final s in kAllSkins)
        if (rewards.owned.contains(s.id)) s,
    ];
    final rarities = <Rarity>[
      for (final r in Rarity.values)
        if (r.weight > 0) r,
    ];
    final totalWeight = rarities.fold<double>(0, (a, r) => a + r.weight);
    final nextMinutes = progress.interval ~/ 60;

    Widget skinRow(List<Skin> skins) => SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: skins.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final skin = skins[i];
              final has = rewards.owned.contains(skin.id);
              return SkinTile(
                skin: skin,
                width: 132,
                owned: has,
                onTap: () => showSkinDetails(
                  context,
                  skin,
                  owned: has,
                  stat: stats[skin.id],
                ),
              );
            },
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas')),
      body: Stack(
        children: [
          Positioned.fill(child: _content(theme, progress, seconds, available, rewards, stats, owned, rarities, totalWeight, nextMinutes, skinRow)),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flash,
                duration: Duration(milliseconds: _flash > 0 ? 40 : 700),
                child: ColoredBox(color: _flashColor.withValues(alpha: 0.55)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    ThemeData theme,
    BoxProgress progress,
    int seconds,
    int available,
    RewardsState rewards,
    Map<String, SkinStat> stats,
    List<Skin> owned,
    List<Rarity> rarities,
    double totalWeight,
    int nextMinutes,
    Widget Function(List<Skin>) skinRow,
  ) {
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          available == 1
                              ? '1 caja sin abrir'
                              : '$available cajas sin abrir',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Próxima caja en ${_clock(progress.remaining)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$nextMinutes min en total',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tiempo en la app: ${formatSeconds(seconds)}. Ganas cajas '
                    'a los 5 minutos y luego a los 10, 20, 40, 80 y después '
                    'cada 100. Se acumulan hasta que las abras.',
                    style: theme.textTheme.bodySmall,
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
                    child: SkinTile(
                      skin: _strip[i],
                      width: _tile - 8,
                      animate: false,
                    ),
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
          const SizedBox(height: 24),
          Text('Todos los aspectos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            'Mira cómo se ve cada uno. Los que tienen candado todavía no los '
            'has ganado.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in kFxColors)
                GestureDetector(
                  onTap: () => setState(() => _previewColor = c.id),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _previewColor == c.id
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Halo · luz detrás de la tarjeta',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          skinRow(skinsOf(SkinFamily.halo, colorId: _previewColor)),
          const SizedBox(height: 16),
          Text('Brillo · la tarjeta entera', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          skinRow(skinsOf(SkinFamily.brillo, colorId: _previewColor)),
          const SizedBox(height: 16),
          Text('Grafitis · de memes a neón', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          skinRow(skinsOf(SkinFamily.grafiti, colorId: _previewColor)),
          const SizedBox(height: 24),
          Text('Tus aspectos (${owned.length}/${kAllSkins.length})',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (owned.isEmpty)
            Text(
              'Todavía no tienes ninguno. Abre tu primera caja para empezar.',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in owned)
                  SkinTile(
                    skin: s,
                    width: 132,
                    onTap: () => showSkinDetails(
                      context,
                      s,
                      owned: true,
                      stat: stats[s.id],
                    ),
                  ),
              ],
            ),
        ],
    );
  }
}
