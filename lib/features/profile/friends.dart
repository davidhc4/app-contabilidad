import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/storage/local_store.dart';
import '../rewards/rewards_state.dart';
import '../rewards/skin_widgets.dart';
import '../rewards/skins.dart';
import 'profile_state.dart';

const _friendsKey = 'amigos';
const _codePrefix = 'BLP1.';

/// Datos de una persona en el ranking de amigos.
class Friend {
  final String name;
  final int seconds;
  final int items;
  const Friend(this.name, this.seconds, this.items);

  Map<String, Object> toJson() => {'n': name, 't': seconds, 'c': items};
}

/// Código con el que compartes tu progreso con un amigo (no usa internet:
/// él lo pega en su app). Los datos son los que dice el código, no se
/// verifican.
String buildProfileCode(String name, int seconds, int items) {
  final data = jsonEncode(Friend(name, seconds, items).toJson());
  return _codePrefix + base64Url.encode(utf8.encode(data));
}

Friend? parseProfileCode(String raw) {
  final text = raw.trim();
  final start = text.indexOf(_codePrefix);
  if (start < 0) return null;
  final code = text.substring(start + _codePrefix.length).split(RegExp(r'\s')).first;
  try {
    final map =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(code))))
            as Map<String, dynamic>;
    final name = (map['n'] as String).trim();
    final seconds = (map['t'] as num).toInt();
    final items = (map['c'] as num).toInt();
    if (name.isEmpty || name.length > 24 || seconds < 0 || items < 0) {
      return null;
    }
    return Friend(name, seconds, items);
  } catch (_) {
    return null;
  }
}

class FriendsNotifier extends Notifier<List<Friend>> {
  @override
  List<Friend> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final raw = await LocalStore.getString(_friendsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      state = [
        for (final m in list)
          Friend(m['n'] as String, (m['t'] as num).toInt(), (m['c'] as num).toInt()),
      ];
    } catch (_) {
      // Archivo dañado: se empieza de cero.
    }
  }

  Future<void> _save() => LocalStore.setString(
        _friendsKey,
        jsonEncode([for (final f in state) f.toJson()]),
      );

  /// Agrega o actualiza (por nombre) a un amigo.
  Future<void> upsert(Friend friend) async {
    state = [
      for (final f in state)
        if (f.name.toLowerCase() != friend.name.toLowerCase()) f,
      friend,
    ];
    await _save();
  }

  Future<void> remove(String name) async {
    state = [for (final f in state) if (f.name != name) f];
    await _save();
  }
}

final friendsProvider =
    NotifierProvider<FriendsNotifier, List<Friend>>(FriendsNotifier.new);

/// Ranking entre tú y los amigos que añadiste con su código.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0; // 0 = tiempo, 1 = aspectos

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Añadir amigo'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Pega aquí el código que te pasó (empieza con BLP1.)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || !mounted) return;
    final friend = parseProfileCode(text);
    final messenger = ScaffoldMessenger.of(context);
    if (friend == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ese código no es válido.')),
      );
      return;
    }
    await ref.read(friendsProvider.notifier).upsert(friend);
    messenger.showSnackBar(
      SnackBar(content: Text('${friend.name} añadido al ranking.')),
    );
  }

  Future<void> _shareMyCode(Friend me) {
    final code = buildProfileCode(me.name, me.seconds, me.items);
    return Share.share(
      'Mi progreso en Bolsillo: ${formatSeconds(me.seconds)} en la app y '
      '${me.items}/${kAllSkins.length} aspectos. Añádeme a tu ranking con '
      'este código:\n$code',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final seconds = ref.watch(usageProvider);
    final owned = ref.watch(rewardsProvider).owned.length;
    final friends = ref.watch(friendsProvider);
    final me = Friend(profile.name.isEmpty ? 'Tú' : profile.name, seconds, owned);

    final rows = [
      (friend: me, isMe: true),
      for (final f in friends) (friend: f, isMe: false),
    ]..sort((a, b) => _tab == 0
        ? b.friend.seconds.compareTo(a.friend.seconds)
        : b.friend.items.compareTo(a.friend.items));

    return Scaffold(
      appBar: AppBar(title: const Text('Amigos y ranking')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'Compite con tus amigos sin internet: cada quien comparte su '
            'código y el otro lo añade. Los datos son los que dice el código, '
            'así que esto es para divertirse entre conocidos.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Tiempo en la app')),
              ButtonSegment(value: 1, label: Text('Aspectos')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: rows[i].isMe ? theme.colorScheme.primaryContainer : null,
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(i == 0 ? '🥇' : (i == 1 ? '🥈' : (i == 2 ? '🥉' : '${i + 1}'))),
                ),
                title: Text(
                  rows[i].isMe ? '${rows[i].friend.name} (tú)' : rows[i].friend.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${formatSeconds(rows[i].friend.seconds)} · '
                  '${rows[i].friend.items}/${kAllSkins.length} aspectos',
                ),
                trailing: rows[i].isMe
                    ? null
                    : IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => ref
                            .read(friendsProvider.notifier)
                            .remove(rows[i].friend.name),
                      ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _shareMyCode(me),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Compartir mi código'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addFriend,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Añadir amigo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
