import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';

const _key = 'tema_halloween';

/// Aviso de que el tema cambió, para lanzar la animación de murciélagos.
/// `toHalloween` es true al activarlo y false al volver al tema normal.
class ThemeSwitchEvent {
  final bool toHalloween;
  final int id;
  const ThemeSwitchEvent(this.toHalloween, this.id);
}

final themeSwitchEventProvider = StateProvider<ThemeSwitchEvent?>((ref) => null);

/// Si el tema de Halloween está activado. Se guarda en el teléfono.
class HalloweenNotifier extends Notifier<bool> {
  int _events = 0;

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
    _events++;
    ref.read(themeSwitchEventProvider.notifier).state =
        ThemeSwitchEvent(value, _events);
    await LocalStore.setString(_key, value ? '1' : '0');
  }
}

final halloweenProvider =
    NotifierProvider<HalloweenNotifier, bool>(HalloweenNotifier.new);
