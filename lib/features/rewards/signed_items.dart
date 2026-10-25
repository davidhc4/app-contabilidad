import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

import 'skins.dart';

/// Llave pública con la que se comprueban los códigos de los aspectos únicos.
/// Solo sirve para verificar: los códigos los firma el creador de la app con
/// una llave privada que nunca está en el repositorio, así que nadie más
/// puede fabricarlos.
const _publicKey = 'CVAMUDJYNvCX1ISerDXshY8T6THmsOtOHP1976V_CYo=';

/// Un código válido: qué aspecto es y su número de serie.
class SignedCode {
  final String itemId;
  final int serial;
  const SignedCode(this.itemId, this.serial);
}

/// Los códigos tienen la forma `BLS.<aspecto>.<número>.<firma>`.
/// Devuelve null si el código no es válido o no está firmado por el creador.
SignedCode? verifyCode(String raw) {
  final parts = raw.trim().split('.');
  if (parts.length != 4 || parts[0] != 'BLS') return null;
  final id = parts[1];
  final serial = int.tryParse(parts[2]);
  final skin = skinById(id);
  if (serial == null || serial < 1 || skin == null || !id.startsWith('u_')) {
    return null;
  }
  try {
    final signature = base64Url.decode(base64Url.normalize(parts[3]));
    final key = ed.PublicKey(base64Url.decode(_publicKey));
    final message = Uint8List.fromList(utf8.encode('bolsillo|$id|$serial'));
    final ok = ed.verify(key, message, Uint8List.fromList(signature));
    return ok ? SignedCode(id, serial) : null;
  } catch (_) {
    return null;
  }
}
