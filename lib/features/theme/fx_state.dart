import '../../core/storage/local_store.dart';

const _k = 'sv_c';
const _m = [5, 25, 50];
const _r = ['x1', 'x2', 'x3'];
int? _n;

/// Cuenta un toque; devuelve un identificador cuando toca premio.
Future<String?> fxTick() async {
  final v = (_n ??= int.tryParse(await LocalStore.getString(_k) ?? '') ?? 0) + 1;
  _n = v;
  await LocalStore.setString(_k, '$v');
  for (var i = 0; i < _m.length; i++) {
    if (v == _m[i] * 2) return _r[i];
  }
  return null;
}
