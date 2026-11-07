import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';

const _key = 'tema_navidad';

/// Si el tema de Navidad está activado. Se guarda en el teléfono.
class NavidadNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final saved = await LocalStore.getString(_key);
    if (saved == '1') state = true;
  }

  Future<void> set(bool value) async {
    if (state == value) return;
    state = value;
    await LocalStore.setString(_key, value ? '1' : '0');
  }
}

final navidadProvider =
    NotifierProvider<NavidadNotifier, bool>(NavidadNotifier.new);

const _counterKey = 'nv_c';
const _thresholds = [10, 50];
const _rewards = ['x4', 'x5'];
int? _taps;

/// Cuenta un toque al trineo; devuelve un identificador cuando toca premio.
Future<String?> sleighTick() async {
  final v = (_taps ??= int.tryParse(await LocalStore.getString(_counterKey) ?? '') ?? 0) + 1;
  _taps = v;
  await LocalStore.setString(_counterKey, '$v');
  for (var i = 0; i < _thresholds.length; i++) {
    if (v == _thresholds[i]) return _rewards[i];
  }
  return null;
}
