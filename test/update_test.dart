import 'package:app_contabilidad/features/updates/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('comparar versiones', () {
    test('detecta cuál es más nueva', () {
      expect(compareVersions('1.14.3', '1.14.2'), greaterThan(0));
      expect(compareVersions('1.15.0', '1.14.9'), greaterThan(0));
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
      expect(compareVersions('1.14.2', '1.14.2'), 0);
    });

    test('acepta la "v" del tag y el número de compilación', () {
      expect(compareVersions('v1.14.3', '1.14.2+24'), greaterThan(0));
      expect(compareVersions('v1.14.2', '1.14.2+24'), 0);
      expect(compareVersions('1.14', '1.14.0'), 0);
    });
  });

  group('respuesta de GitHub', () {
    const body = '''
{
  "tag_name": "v9.9.9",
  "name": "Bolsillo v9.9.9",
  "assets": [
    {"name": "notas.txt", "size": 10,
     "browser_download_url": "https://github.com/davidhc4/app-contabilidad/releases/download/v9.9.9/notas.txt"},
    {"name": "bolsillo-v9.9.9.apk", "size": 66832584,
     "digest": "sha256:1EE01AEC7f5d7cb5e9abae58c5321796df1162b7d1e025b06e718c4b18095171",
     "browser_download_url": "https://github.com/davidhc4/app-contabilidad/releases/download/v9.9.9/bolsillo-v9.9.9.apk"}
  ]
}''';

    test('saca la versión, el APK, el tamaño y la huella', () {
      final info = parseLatestRelease(body);
      expect(info.version, '9.9.9');
      expect(info.isNewer, isTrue);
      expect(info.url, endsWith('/v9.9.9/bolsillo-v9.9.9.apk'));
      expect(info.size, 66832584);
      expect(info.sha256,
          '1ee01aec7f5d7cb5e9abae58c5321796df1162b7d1e025b06e718c4b18095171');
    });

    test('ignora APK que no están en los Releases del repositorio', () {
      final info = parseLatestRelease('''
{"tag_name": "v9.9.9", "assets": [
  {"name": "malo.apk", "size": 1,
   "browser_download_url": "https://ejemplo.com/malo.apk"}]}''');
      expect(info.url, isNull);
    });

    test('una versión sin archivos no trae APK', () {
      final info = parseLatestRelease('{"tag_name": "v0.0.1", "assets": []}');
      expect(info.url, isNull);
      expect(info.isNewer, isFalse);
    });

    test('rechaza respuestas que no son una versión', () {
      expect(() => parseLatestRelease('[]'), throwsFormatException);
      expect(() => parseLatestRelease('{"message": "Not Found"}'),
          throwsFormatException);
    });
  });
}
