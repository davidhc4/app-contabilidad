import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_version.dart';

/// Repositorio de GitHub donde se publican las versiones de la app.
const kUpdateRepo = 'davidhc4/app-contabilidad';

const _latestUrl = 'https://api.github.com/repos/$kUpdateRepo/releases/latest';
const _downloadPrefix = 'https://github.com/$kUpdateRepo/releases/download/';
const _channel = MethodChannel('com.davidcontabilidad.app_contabilidad/updates');

/// Error con un mensaje listo para mostrarle a la persona.
class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);

  @override
  String toString() => message;
}

/// La versión más reciente publicada en GitHub.
class UpdateInfo {
  final String version;

  /// Dirección del APK. Es null si la versión aún no tiene el archivo.
  final String? url;
  final int size;

  /// Huella SHA-256 del APK según GitHub (en minúsculas), si la publica.
  final String? sha256;

  const UpdateInfo({
    required this.version,
    required this.url,
    required this.size,
    required this.sha256,
  });

  /// Si esta versión es más nueva que la instalada.
  bool get isNewer => compareVersions(version, kAppVersion) > 0;
}

/// Compara dos versiones tipo "1.14.2" (acepta "v" al inicio y "+12" al
/// final). Devuelve un número positivo si [a] es más nueva que [b].
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .trim()
      .replaceFirst(RegExp('^[vV]'), '')
      .split('+')
      .first
      .split('.')
      .map((e) => int.tryParse(e.trim()) ?? 0)
      .toList();
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final diff = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (diff != 0) return diff;
  }
  return 0;
}

/// Lee la respuesta de GitHub ("releases/latest").
UpdateInfo parseLatestRelease(String body) {
  final data = jsonDecode(body);
  if (data is! Map<String, dynamic>) {
    throw const FormatException('respuesta inesperada');
  }
  final tag = data['tag_name'];
  if (tag is! String || tag.isEmpty) {
    throw const FormatException('falta la versión');
  }
  String? url;
  var size = 0;
  String? hash;
  final assets = data['assets'];
  if (assets is List) {
    for (final a in assets) {
      if (a is! Map<String, dynamic>) continue;
      final name = a['name'];
      final link = a['browser_download_url'];
      // Solo se aceptan APK alojados en los Releases de este repositorio.
      if (name is String &&
          link is String &&
          name.toLowerCase().endsWith('.apk') &&
          link.startsWith(_downloadPrefix)) {
        url = link;
        size = a['size'] is num ? (a['size'] as num).toInt() : 0;
        final digest = a['digest'];
        if (digest is String && digest.startsWith('sha256:')) {
          hash = digest.substring(7).toLowerCase();
        }
        break;
      }
    }
  }
  return UpdateInfo(
    version: tag.replaceFirst(RegExp('^[vV]'), ''),
    url: url,
    size: size,
    sha256: hash,
  );
}

HttpClient _client() => HttpClient()
  ..connectionTimeout = const Duration(seconds: 15)
  ..userAgent = 'Bolsillo/$kAppVersion';

Never _network(Object e) {
  if (e is UpdateException) throw e;
  if (e is TimeoutException) {
    throw const UpdateException(
        'La conexión está muy lenta. Intenta de nuevo en un momento.');
  }
  if (e is SocketException || e is HandshakeException || e is HttpException) {
    throw const UpdateException(
        'No se pudo conectar con GitHub. Revisa tu conexión a internet.');
  }
  if (e is FormatException) {
    throw const UpdateException(
        'GitHub respondió algo inesperado. Intenta más tarde.');
  }
  throw UpdateException('Algo falló: $e');
}

/// Pregunta a GitHub cuál es la última versión publicada. Es la única
/// conexión a internet que hace la app, y solo ocurre cuando la persona
/// toca "Buscar actualizaciones".
Future<UpdateInfo> fetchLatestRelease() async {
  final client = _client();
  try {
    final request = await client.getUrl(Uri.parse(_latestUrl));
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close().timeout(const Duration(seconds: 20));
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw const UpdateException(
          'GitHub recibió muchas consultas desde tu red. Intenta en unos minutos.');
    }
    if (response.statusCode != 200) {
      throw UpdateException(
          'GitHub respondió con un error (${response.statusCode}). Intenta más tarde.');
    }
    return parseLatestRelease(body);
  } catch (e) {
    _network(e);
  } finally {
    client.close(force: true);
  }
}

Future<Directory> _updatesDir() async =>
    Directory(p.join((await getTemporaryDirectory()).path, 'updates'));

Future<bool> _matches(File file, UpdateInfo info) async {
  if (!await file.exists()) return false;
  if (info.size > 0 && await file.length() != info.size) return false;
  final expected = info.sha256;
  if (expected != null) {
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString() != expected) return false;
  }
  return true;
}

/// Borra los APK descargados (ya no hacen falta cuando la app está al día).
Future<void> clearDownloads() async {
  try {
    final dir = await _updatesDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (_) {
    // Si no se puede borrar, Android lo limpia con la caché.
  }
}

/// Descarga el APK de [info] y comprueba que llegó completo y sin cambios
/// (tamaño y huella SHA-256 que publica GitHub). Si ya estaba descargado y
/// es correcto, lo reutiliza.
Future<File> downloadUpdate(
  UpdateInfo info,
  void Function(double progress) onProgress,
) async {
  final url = info.url;
  if (url == null || !url.startsWith(_downloadPrefix)) {
    throw const UpdateException(
        'Esa versión todavía se está publicando. Intenta en unos minutos.');
  }
  final dir = await _updatesDir();
  final file = File(p.join(dir.path, 'bolsillo-v${info.version}.apk'));
  if (await _matches(file, info)) {
    onProgress(1);
    return file;
  }
  await clearDownloads();
  await dir.create(recursive: true);

  final client = _client();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw UpdateException(
          'No se pudo descargar la actualización (error ${response.statusCode}).');
    }
    final total = response.contentLength > 0 ? response.contentLength : info.size;
    final sink = file.openWrite();
    var received = 0;
    var lastPercent = -1;
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          var percent = received * 100 ~/ total;
          if (percent > 100) percent = 100;
          if (percent != lastPercent) {
            lastPercent = percent;
            onProgress(percent / 100);
          }
        }
      }
    } finally {
      await sink.close();
    }
    if (!await _matches(file, info)) {
      throw const UpdateException(
          'La descarga llegó incompleta o dañada. Intenta de nuevo.');
    }
    return file;
  } catch (e) {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Nada que hacer: se reemplaza en el próximo intento.
    }
    _network(e);
  } finally {
    client.close(force: true);
  }
}

/// Si Android ya le permite a la app instalar actualizaciones.
Future<bool> canInstallUpdates() async {
  try {
    return await _channel.invokeMethod<bool>('canInstall') ?? true;
  } on PlatformException {
    return true;
  } on MissingPluginException {
    return false;
  }
}

/// Abre la pantalla de Android "Instalar apps desconocidas" para esta app.
Future<void> openInstallPermission() async {
  try {
    await _channel.invokeMethod<void>('openInstallSettings');
  } on PlatformException {
    // Si no abre, el instalador de Android lo pedirá igual.
  } on MissingPluginException {
    // Solo existe en Android.
  }
}

/// Abre el instalador de Android con el APK descargado.
Future<void> installUpdate(File file) async {
  try {
    await _channel.invokeMethod<void>('install', {'path': file.path});
  } on PlatformException catch (e) {
    throw UpdateException('No se pudo abrir el instalador: ${e.message ?? e.code}');
  } on MissingPluginException {
    throw const UpdateException('La instalación solo funciona en Android.');
  }
}
