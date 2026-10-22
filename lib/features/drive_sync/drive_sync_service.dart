import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Datos de conexión con el script de Google (Apps Script) que escribe en
/// la hoja de la carpeta FINANZAS del Drive del usuario.
class DriveSyncConfig {
  final String url;
  final String token;
  const DriveSyncConfig({required this.url, required this.token});

  static const _urlKey = 'drive_sync_url';
  static const _tokenKey = 'drive_sync_token';

  /// Solo se aceptan direcciones de Google Apps Script, para no enviar
  /// nunca tus datos a un sitio desconocido.
  static bool isValidUrl(String url) =>
      url.startsWith('https://script.google.com/');

  static Future<DriveSyncConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_urlKey);
    final token = prefs.getString(_tokenKey);
    if (url == null || token == null || !isValidUrl(url)) return null;
    return DriveSyncConfig(url: url, token: token);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
    await prefs.remove(_tokenKey);
  }
}

class DriveSyncException implements Exception {
  final String message;
  DriveSyncException(this.message);
  @override
  String toString() => message;
}

/// Envía todos los movimientos al script de Google, que reemplaza el
/// contenido de la hoja "Movimientos" (así nunca quedan filas duplicadas).
/// Devuelve cuántas filas quedaron en la hoja.
Future<int> sendRowsToDrive(
  DriveSyncConfig config,
  List<List<Object>> rows,
) async {
  if (!DriveSyncConfig.isValidUrl(config.url)) {
    throw DriveSyncException('La dirección del script no es válida');
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final payload = utf8.encode(jsonEncode({'token': config.token, 'rows': rows}));
    final request = await client.postUrl(Uri.parse(config.url));
    request.followRedirects = false;
    request.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
    request.add(payload);
    var response = await request.close().timeout(const Duration(seconds: 90));

    // Google responde con una redirección (302) a la dirección donde está
    // el resultado; se lee con GET (el envío ya se hizo con el POST).
    var hops = 0;
    while ({301, 302, 303, 307, 308}.contains(response.statusCode) && hops < 3) {
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null) break;
      final next = Uri.parse(location);
      if (next.scheme != 'https' || !next.host.endsWith('google.com') &&
          !next.host.endsWith('googleusercontent.com')) {
        throw DriveSyncException('Respuesta inesperada del servidor');
      }
      final getRequest = await client.getUrl(next);
      getRequest.followRedirects = false;
      response = await getRequest.close().timeout(const Duration(seconds: 60));
      hops++;
    }

    final body = await utf8.decodeStream(response);
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw DriveSyncException(
        'El script no respondió como se esperaba. Revisa que esté '
        'implementado como aplicación web con acceso para "Cualquier '
        'persona".',
      );
    }
    if (json['ok'] != true) {
      throw DriveSyncException((json['error'] ?? 'Error desconocido').toString());
    }
    return (json['count'] as num?)?.toInt() ?? rows.length;
  } on SocketException {
    throw DriveSyncException('Sin conexión a internet');
  } on TimeoutException {
    throw DriveSyncException('Tardó demasiado en responder. Inténtalo de nuevo');
  } finally {
    client.close();
  }
}
