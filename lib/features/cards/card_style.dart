import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/local_store.dart';

/// Colores de fondo con los que empiezan las tarjetas nuevas (grafito). El
/// color y los efectos especiales vienen de los aspectos que se ganan.
const kCardStart = 'FF2C2F3B';
const kCardEnd = 'FF15171D';

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

const kStickersHalloween = <String>[
  '🎃', '👻', '🦇', '🕷️', '🕸️', '💀', '🧙', '🍬', //
  '🧛', '🧟', '🌙', '🔮', '🪦', '🍭', '😈', '🐈‍⬛',
];

/// Decoración opcional de una tarjeta: una foto del celular de fondo y/o un
/// sticker encima. Se guarda aparte de la base de datos (en preferencias)
/// para no tener que cambiar el esquema de la base de datos.
class CardStyle {
  final String? photoPath;
  final String? sticker;

  /// Dinero que ya tenía la tarjeta/cuenta antes de usar la app.
  final double? initialBalance;

  /// Identificador del aspecto especial elegido (ver recompensas).
  final String? skin;

  const CardStyle({
    this.photoPath,
    this.sticker,
    this.initialBalance,
    this.skin,
  });

  static const empty = CardStyle();

  bool get isEmpty =>
      photoPath == null &&
      sticker == null &&
      initialBalance == null &&
      skin == null;

  CardStyle copyWith({
    String? photoPath,
    String? sticker,
    double? initialBalance,
    String? skin,
    bool clearPhoto = false,
    bool clearSticker = false,
  }) {
    return CardStyle(
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      sticker: clearSticker ? null : (sticker ?? this.sticker),
      initialBalance: initialBalance ?? this.initialBalance,
      skin: skin ?? this.skin,
    );
  }

  String toJson() => jsonEncode({
        'photo': photoPath,
        'sticker': sticker,
        'initial': initialBalance,
        'skin': skin,
      });

  static CardStyle fromJson(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CardStyle(
        photoPath: map['photo'] as String?,
        sticker: map['sticker'] as String?,
        initialBalance: (map['initial'] as num?)?.toDouble(),
        skin: map['skin'] as String?,
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
    final saved = await LocalStore.allWithPrefix(_prefix);
    final loaded = <String, CardStyle>{
      for (final e in saved.entries)
        e.key.substring(_prefix.length): CardStyle.fromJson(e.value),
    };
    state = {...loaded, ...state};
  }

  /// Guarda la foto elegida en la carpeta privada de la app en el momento
  /// de elegirla (la ruta temporal del selector puede desaparecer antes de
  /// que el usuario toque "Guardar"). Devuelve la ruta definitiva.
  Future<String> savePickedPhoto(XFile picked, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'card_photos'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final target = p.join(
      folder.path,
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final bytes = await picked.readAsBytes();
    await File(target).writeAsBytes(bytes, flush: true);
    if (!await File(target).exists()) {
      throw const FileSystemException('No se pudo guardar la foto');
    }
    return target;
  }

  /// Borra un archivo de foto que ya no se usa.
  Future<void> discardPhoto(String path) => _deleteFile(path);

  Future<void> setStyle(String cardId, CardStyle style) async {
    final previous = state[cardId];
    if (style.isEmpty) {
      await LocalStore.remove('$_prefix$cardId');
      final next = {...state}..remove(cardId);
      state = next;
    } else {
      await LocalStore.setString('$_prefix$cardId', style.toJson());
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
