import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import 'skins.dart';

const _usageKey = 'uso_segundos';
const _spinsKey = 'cajas_abiertas';
const _skinsKey = 'aspectos_ok';

/// Cada cuántos segundos dentro de la app se gana una caja (10 minutos).
const kSecondsPerBox = 600;

/// Segundos que la persona ha pasado dentro de la app (acumulados).
class UsageNotifier extends Notifier<int> {
  Timer? _timer;
  bool _foreground = true;
  bool _loaded = false;
  int _unsaved = 0;

  @override
  int build() {
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  Future<void> _load() async {
    final saved = int.tryParse(await LocalStore.getString(_usageKey) ?? '') ?? 0;
    state = state + saved;
    _loaded = true;
  }

  void _tick() {
    if (!_foreground || !_loaded) return;
    state = state + 1;
    _unsaved++;
    if (_unsaved >= 15) _save();
  }

  /// Avisa si la app está a la vista; al salir se guarda lo acumulado.
  void setForeground(bool value) {
    _foreground = value;
    if (!value && _loaded) _save();
  }

  void _save() {
    _unsaved = 0;
    LocalStore.setString(_usageKey, '$state');
  }
}

final usageProvider = NotifierProvider<UsageNotifier, int>(UsageNotifier.new);

class RewardsState {
  final Set<String> owned;
  final int boxesOpened;
  const RewardsState({required this.owned, required this.boxesOpened});
}

class RewardsNotifier extends Notifier<RewardsState> {
  @override
  RewardsState build() {
    _load();
    return const RewardsState(owned: {kStartSkinId}, boxesOpened: 0);
  }

  Future<void> _load() async {
    final ids = (await LocalStore.getString(_skinsKey) ?? '')
        .split(',')
        .where((e) => e.isNotEmpty);
    final opened = int.tryParse(await LocalStore.getString(_spinsKey) ?? '') ?? 0;
    state = RewardsState(
      owned: {kStartSkinId, ...ids, ...state.owned},
      boxesOpened: math.max(opened, state.boxesOpened),
    );
  }

  Future<void> useBox() async {
    state = RewardsState(owned: state.owned, boxesOpened: state.boxesOpened + 1);
    await LocalStore.setString(_spinsKey, '${state.boxesOpened}');
  }

  /// Agrega un aspecto. Devuelve false si ya lo tenía.
  Future<bool> grant(String id) async {
    if (state.owned.contains(id)) return false;
    state = RewardsState(
      owned: {...state.owned, id},
      boxesOpened: state.boxesOpened,
    );
    await LocalStore.setString(_skinsKey, state.owned.join(','));
    return true;
  }
}

final rewardsProvider =
    NotifierProvider<RewardsNotifier, RewardsState>(RewardsNotifier.new);

/// Sortea un aspecto de las cajas según las probabilidades de cada rareza.
Skin pickSkin(math.Random rng) {
  final rarities = <Rarity>{for (final s in kSkins) s.rarity};
  final total = rarities.fold<double>(0, (sum, r) => sum + r.weight);
  var roll = rng.nextDouble() * total;
  var chosen = rarities.first;
  for (final r in rarities) {
    if (roll < r.weight) {
      chosen = r;
      break;
    }
    roll -= r.weight;
  }
  final pool = kSkins.where((s) => s.rarity == chosen).toList();
  return pool[rng.nextInt(pool.length)];
}
