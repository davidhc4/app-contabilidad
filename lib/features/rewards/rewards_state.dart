import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import '../cards/card_style.dart';
import 'signed_items.dart';
import 'skins.dart';

const _usageKey = 'uso_segundos';
const _spinsKey = 'cajas_abiertas';
const _skinsKey = 'aspectos_ok';
const _seenKey = 'aspectos_vistos';
const _statsKey = 'aspectos_uso';
const _serialsKey = 'aspectos_serie';

/// Minutos que hay que pasar en la app para ganar la caja número [n]
/// (empezando en 0): 5, 10, 20, 40, 80 y luego siempre 100.
int boxIntervalMinutes(int n) => n >= 5 ? 100 : 5 << n;

/// Cuántas cajas se han ganado en total y cómo va la siguiente.
class BoxProgress {
  /// Cajas ganadas desde que se instaló la app.
  final int earned;

  /// Segundos acumulados hacia la siguiente caja.
  final int into;

  /// Segundos que dura el tramo de la siguiente caja.
  final int interval;

  const BoxProgress(this.earned, this.into, this.interval);

  double get fraction => interval == 0 ? 0 : into / interval;
  int get remaining => interval - into;
}

BoxProgress boxProgress(int seconds) {
  var left = seconds;
  var n = 0;
  while (true) {
    final interval = boxIntervalMinutes(n) * 60;
    if (left < interval) return BoxProgress(n, left, interval);
    left -= interval;
    n++;
  }
}

/// Aviso que se muestra dentro de la app (por ejemplo "nuevo aspecto").
class Notice {
  final String text;
  final int id;
  const Notice(this.text, this.id);
}

final noticeProvider = StateProvider<Notice?>((ref) => null);
int _noticeCount = 0;

void _notify(Ref ref, String text) {
  ref.read(noticeProvider.notifier).state = Notice(text, ++_noticeCount);
}

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
    // Quien ya había abierto más cajas de las que da el nuevo reparto no se
    // queda "debiendo" cajas.
    ref.read(rewardsProvider.notifier).reconcile(boxProgress(state).earned);
  }

  void _tick() {
    if (!_foreground || !_loaded) return;
    final before = boxProgress(state).earned;
    state = state + 1;
    final after = boxProgress(state).earned;
    if (after > before) {
      final opened = ref.read(rewardsProvider).boxesOpened;
      final waiting = math.max(0, after - opened);
      _notify(
        ref,
        waiting <= 1
            ? '¡Ganaste una caja! Ábrela desde tu perfil.'
            : '¡Ganaste una caja! Ya tienes $waiting sin abrir.',
      );
    }
    final applied = {
      for (final style in ref.read(cardStylesProvider).values)
        if (style.skin != null) style.skin!,
    };
    if (applied.isNotEmpty) {
      ref.read(skinStatsProvider.notifier).addSecond(applied);
    }
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
    ref.read(skinStatsProvider.notifier).persist();
  }
}

final usageProvider = NotifierProvider<UsageNotifier, int>(UsageNotifier.new);

final boxProgressProvider =
    Provider<BoxProgress>((ref) => boxProgress(ref.watch(usageProvider)));

/// Cajas ganadas que todavía no se han abierto.
final availableBoxesProvider = Provider<int>((ref) {
  final earned = ref.watch(boxProgressProvider).earned;
  final opened = ref.watch(rewardsProvider).boxesOpened;
  return math.max(0, earned - opened);
});

class RewardsState {
  final Set<String> owned;
  final Set<String> seen;
  final int boxesOpened;

  /// Número de serie de los aspectos únicos que se canjearon con código.
  final Map<String, int> serials;
  const RewardsState({
    required this.owned,
    required this.boxesOpened,
    required this.seen,
    this.serials = const {},
  });

  RewardsState copyWith({
    Set<String>? owned,
    Set<String>? seen,
    int? boxesOpened,
    Map<String, int>? serials,
  }) =>
      RewardsState(
        owned: owned ?? this.owned,
        seen: seen ?? this.seen,
        boxesOpened: boxesOpened ?? this.boxesOpened,
        serials: serials ?? this.serials,
      );
}

class RewardsNotifier extends Notifier<RewardsState> {
  late Future<void> ready;

  @override
  RewardsState build() {
    ready = _load();
    return const RewardsState(owned: {}, boxesOpened: 0, seen: {});
  }

  static Set<String> _ids(String? raw) => {
        for (final id in (raw ?? '').split(','))
          if (id.isNotEmpty) id,
      };

  Future<void> _load() async {
    final owned = _ids(await LocalStore.getString(_skinsKey))
        .where((id) => skinById(id) != null)
        .toSet();
    final seen = _ids(await LocalStore.getString(_seenKey));
    final opened = int.tryParse(await LocalStore.getString(_spinsKey) ?? '') ?? 0;
    var serials = <String, int>{};
    try {
      final raw = await LocalStore.getString(_serialsKey);
      if (raw != null) {
        serials = {
          for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
            e.key: (e.value as num).toInt(),
        };
      }
    } catch (_) {
      // Si el archivo está dañado se ignora.
    }
    state = RewardsState(
      owned: {...owned, ...state.owned},
      seen: {...seen, ...state.seen},
      boxesOpened: math.max(opened, state.boxesOpened),
      serials: {...serials, ...state.serials},
    );
    final fresh = state.owned.difference(state.seen);
    if (fresh.isNotEmpty) {
      final first = skinById(fresh.first);
      _notify(
        ref,
        fresh.length == 1 && first != null
            ? 'Tienes un nuevo aspecto: ${first.name} (${first.rarity.label}). '
                'Pruébalo en tus tarjetas.'
            : 'Tienes ${fresh.length} aspectos nuevos para tus tarjetas.',
      );
    }
  }

  Future<void> reconcile(int earned) async {
    await ready;
    if (state.boxesOpened > earned) {
      state = state.copyWith(boxesOpened: earned);
      await LocalStore.setString(_spinsKey, '$earned');
    }
  }

  Future<void> useBox() async {
    state = state.copyWith(boxesOpened: state.boxesOpened + 1);
    await LocalStore.setString(_spinsKey, '${state.boxesOpened}');
  }

  /// Agrega un aspecto. Devuelve false si ya lo tenía. Con [announce] avisa
  /// dentro de la app que hay un aspecto nuevo.
  Future<bool> grant(String id, {bool announce = true}) async {
    final skin = skinById(id);
    if (skin == null || state.owned.contains(id)) return false;
    state = state.copyWith(owned: {...state.owned, id});
    await LocalStore.setString(_skinsKey, state.owned.join(','));
    if (announce) {
      _notify(
        ref,
        'Tienes un nuevo aspecto: ${skin.name} (${skin.rarity.label}). '
        'Pruébalo en tus tarjetas.',
      );
    }
    return true;
  }

  /// Canjea un código de aspecto único. Devuelve un mensaje para mostrar.
  Future<String> redeem(String code) async {
    final signed = verifyCode(code);
    if (signed == null) {
      return 'Ese código no es válido. Revisa que esté completo y sin espacios.';
    }
    final skin = skinById(signed.itemId)!;
    if (state.owned.contains(signed.itemId)) {
      return 'Ya tienes "${skin.name}".';
    }
    state = state.copyWith(
      serials: {...state.serials, signed.itemId: signed.serial},
    );
    await LocalStore.setString(_serialsKey, jsonEncode(state.serials));
    await grant(signed.itemId);
    return '¡Canjeado! "${skin.name}" (único Nº ${signed.serial}) ya es tuyo.';
  }

  /// Marca como vistos los aspectos (al entrar al perfil o a recompensas).
  Future<void> markAllSeen() async {
    if (state.owned.difference(state.seen).isEmpty) return;
    state = state.copyWith(seen: {...state.owned});
    await LocalStore.setString(_seenKey, state.seen.join(','));
  }
}

final rewardsProvider =
    NotifierProvider<RewardsNotifier, RewardsState>(RewardsNotifier.new);

/// Aspectos ganados que la persona todavía no ha visto.
final unseenSkinsProvider = Provider<List<Skin>>((ref) {
  final r = ref.watch(rewardsProvider);
  return [
    for (final id in r.owned.difference(r.seen))
      if (skinById(id) != null) skinById(id)!,
  ];
});

/// Uso de un aspecto: cuántas veces se puso y cuánto tiempo estuvo puesto.
class SkinStat {
  final int seconds;
  final int uses;
  final int firstApplied;
  final int lastApplied;
  const SkinStat({
    this.seconds = 0,
    this.uses = 0,
    this.firstApplied = 0,
    this.lastApplied = 0,
  });

  SkinStat copyWith({int? seconds, int? uses, int? firstApplied, int? lastApplied}) =>
      SkinStat(
        seconds: seconds ?? this.seconds,
        uses: uses ?? this.uses,
        firstApplied: firstApplied ?? this.firstApplied,
        lastApplied: lastApplied ?? this.lastApplied,
      );

  List<int> toJson() => [seconds, uses, firstApplied, lastApplied];

  static SkinStat fromJson(Object? raw) {
    if (raw is List && raw.length >= 4) {
      int n(int i) => raw[i] is num ? (raw[i] as num).toInt() : 0;
      return SkinStat(
        seconds: n(0),
        uses: n(1),
        firstApplied: n(2),
        lastApplied: n(3),
      );
    }
    return const SkinStat();
  }
}

class SkinStatsNotifier extends Notifier<Map<String, SkinStat>> {
  @override
  Map<String, SkinStat> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final raw = await LocalStore.getString(_statsKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = {
        for (final e in map.entries) e.key: SkinStat.fromJson(e.value),
      };
      // Lo que se haya contado mientras cargaba se suma a lo guardado.
      state = {
        ...loaded,
        for (final e in state.entries)
          e.key: loaded.containsKey(e.key)
              ? loaded[e.key]!.copyWith(
                  seconds: loaded[e.key]!.seconds + e.value.seconds,
                  uses: math.max(loaded[e.key]!.uses, e.value.uses),
                  lastApplied: math.max(
                      loaded[e.key]!.lastApplied, e.value.lastApplied),
                )
              : e.value,
      };
    } catch (_) {
      // Si el archivo está dañado se empieza de cero.
    }
  }

  /// Se llama al guardar una tarjeta con este aspecto puesto.
  void noteApplied(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = state[id] ?? const SkinStat();
    state = {
      ...state,
      id: current.copyWith(
        uses: current.uses + 1,
        firstApplied: current.firstApplied == 0 ? now : current.firstApplied,
        lastApplied: now,
      ),
    };
    persist();
  }

  /// Suma un segundo a cada aspecto que está puesto en alguna tarjeta.
  void addSecond(Set<String> ids) {
    final next = {...state};
    for (final id in ids) {
      final current = next[id] ?? const SkinStat();
      next[id] = current.copyWith(seconds: current.seconds + 1);
    }
    state = next;
  }

  Future<void> persist() => LocalStore.setString(
        _statsKey,
        jsonEncode({for (final e in state.entries) e.key: e.value.toJson()}),
      );
}

final skinStatsProvider =
    NotifierProvider<SkinStatsNotifier, Map<String, SkinStat>>(
  SkinStatsNotifier.new,
);

/// Aspectos ganados que nunca se han puesto en una tarjeta.
final unusedSkinsProvider = Provider<List<Skin>>((ref) {
  final owned = ref.watch(rewardsProvider).owned;
  final stats = ref.watch(skinStatsProvider);
  return [
    for (final id in owned)
      if ((stats[id]?.uses ?? 0) == 0 && skinById(id) != null) skinById(id)!,
  ];
});

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
