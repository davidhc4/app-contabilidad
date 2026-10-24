import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/local_store.dart';

const _nameKey = 'perfil_nombre';
const _bioKey = 'perfil_bio';
const _photoKey = 'perfil_foto';

/// Datos del perfil de la persona. Todo se queda en el teléfono.
class Profile {
  final String name;
  final String bio;
  final String? photoPath;
  const Profile({this.name = '', this.bio = '', this.photoPath});

  Profile copyWith({String? name, String? bio, String? photoPath, bool clearPhoto = false}) =>
      Profile(
        name: name ?? this.name,
        bio: bio ?? this.bio,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      );
}

class ProfileNotifier extends Notifier<Profile> {
  @override
  Profile build() {
    _load();
    return const Profile();
  }

  Future<void> _load() async {
    final name = await LocalStore.getString(_nameKey) ?? '';
    final bio = await LocalStore.getString(_bioKey) ?? '';
    final photo = await LocalStore.getString(_photoKey);
    state = Profile(
      name: state.name.isNotEmpty ? state.name : name,
      bio: state.bio.isNotEmpty ? state.bio : bio,
      photoPath: state.photoPath ?? ((photo != null && File(photo).existsSync()) ? photo : null),
    );
  }

  Future<void> setTexts({required String name, required String bio}) async {
    state = state.copyWith(name: name.trim(), bio: bio.trim());
    await LocalStore.setString(_nameKey, state.name);
    await LocalStore.setString(_bioKey, state.bio);
  }

  /// Guarda la foto elegida en la carpeta privada de la app.
  Future<void> setPhoto(XFile picked) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'profile'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final target = p.join(
      folder.path,
      'foto_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(target).writeAsBytes(await picked.readAsBytes(), flush: true);
    final old = state.photoPath;
    state = state.copyWith(photoPath: target);
    await LocalStore.setString(_photoKey, target);
    await _delete(old);
  }

  Future<void> clearPhoto() async {
    final old = state.photoPath;
    state = state.copyWith(clearPhoto: true);
    await LocalStore.remove(_photoKey);
    await _delete(old);
  }

  Future<void> _delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Si no se puede borrar no pasa nada.
    }
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);
