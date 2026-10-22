import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guardado sencillo de pares clave/valor en un archivo JSON dentro de la
/// carpeta privada de la app. Reemplaza a SharedPreferences, cuyo plugin
/// nativo fallaba en este celular ("NoSuchMethodError ... getAll").
class LocalStore {
  LocalStore._();

  static Map<String, dynamic>? _cache;
  static Future<void> _queue = Future<void>.value();

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'local_store.json'));
  }

  static Future<Map<String, dynamic>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    Map<String, dynamic> data = {};
    try {
      final file = await _file();
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) data = decoded;
      }
    } catch (_) {
      data = {};
    }
    _cache = data;
    return data;
  }

  /// Escribe en orden y de forma segura (primero a un archivo temporal).
  static Future<void> _persist() {
    _queue = _queue.then((_) async {
      final data = await _load();
      final file = await _file();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(data), flush: true);
      await tmp.rename(file.path);
    });
    return _queue;
  }

  static Future<String?> getString(String key) async {
    final data = await _load();
    final value = data[key];
    return value is String ? value : null;
  }

  static Future<Map<String, String>> allWithPrefix(String prefix) async {
    final data = await _load();
    return {
      for (final e in data.entries)
        if (e.key.startsWith(prefix) && e.value is String)
          e.key: e.value as String,
    };
  }

  static Future<void> setString(String key, String value) async {
    final data = await _load();
    data[key] = value;
    await _persist();
  }

  static Future<void> remove(String key) async {
    final data = await _load();
    data.remove(key);
    await _persist();
  }
}
