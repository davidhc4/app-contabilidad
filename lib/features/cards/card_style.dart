import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stickers disponibles para decorar una tarjeta. Son emojis, así que no
/// dependen de ninguna imagen con derechos de autor y se ven en cualquier
/// celular.
const kStickersMujer = <String>[
  '🌸', '🌷', '🦋', '🎀', '💖', '💋', '👑', '🍒', //
  '⭐', '🐯', '💅', '🌈', '✨', '🍓', '🐱', '🌻',
];

const kStickersHombre = <String>[
  '🦁', '⚡', '🏆', '🚀', '🔥', '🎧', '⚽', '🏍️', //
  '🐺', '🎮', '🦅', '🌵', '🎸', '🏀', '💎', '🦈',
];

/// Decoración opcional de una tarjeta: una foto del celular de fondo y/o un
/// sticker encima. Se guarda aparte de la base de datos (en preferencias)
/// para no tener que cambiar el esquema de la base de datos.
class CardStyle {
  final String? photoPath;
  final String? sticker;

  const CardStyle({this.photoPath, this.sticker});

  static const empty = CardStyle();

  bool get isEmpty => photoPath == null && sticker == null;

  CardStyle copyWith({
    String? photoPath,
    String? sticker,
    bool clearPhoto = false,
    bool clearSticker = false,
  }) {
    return CardStyle(
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      sticker: clearSticker ? null : (sticker ?? this.sticker),
    );
  }

  String toJson() => jsonEncode({'photo': photoPath, 'sticker': sticker});

  static CardStyle fromJson(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CardStyle(
        photoPath: map['photo'] as String?,
        sticker: map['sticker'] as String?,
      );
    } catch (_) {
      return CardStyle.empty;
    }
  }
}

const _prefix = 'card_style_';

/// Guarda y expone el estilo (foto/sticker) de cada tarjeta por su id.
class CardStylesNotifier extends Notifier<Map<String, CardStyle>> {
  @override
  Map<String, CardStyle> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, CardStyle>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      loaded[key.substring(_prefix.length)] = CardStyle.fromJson(raw);
    }
    state = {...loaded, ...state};
  }

  /// Copia la foto elegida a la carpeta privada de la app (la ruta que da
  /// el selector es temporal y el sistema puede borrarla).
  Future<String> persistPhoto(String sourcePath, String cardId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'card_photos'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final target = p.join(
      folder.path,
      '${cardId}_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(sourcePath).copy(target);
    return target;
  }

  Future<void> setStyle(String cardId, CardStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = state[cardId];
    if (style.isEmpty) {
      await prefs.remove('$_prefix$cardId');
      final next = {...state}..remove(cardId);
      state = next;
    } else {
      await prefs.setString('$_prefix$cardId', style.toJson());
      state = {...state, cardId: style};
    }
    // Si se cambió o quitó la foto, borra el archivo anterior.
    final oldPhoto = previous?.photoPath;
    if (oldPhoto != null && oldPhoto != style.photoPath) {
      await _deleteFile(oldPhoto);
    }
  }

  Future<void> remove(String cardId) => setStyle(cardId, CardStyle.empty);

  Future<void> _deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Si no se puede borrar el archivo no pasa nada.
    }
  }
}

final cardStylesProvider =
    NotifierProvider<CardStylesNotifier, Map<String, CardStyle>>(
  CardStylesNotifier.new,
);
