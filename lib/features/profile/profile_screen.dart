import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/platform/gallery_permission.dart';
import '../rewards/rewards_screen.dart';
import '../rewards/rewards_state.dart';
import '../rewards/skin_widgets.dart';
import '../rewards/skins.dart';
import 'friends.dart';
import 'profile_state.dart';

/// Foto (o inicial) del perfil. Con [badge] muestra un puntito si hay cajas
/// sin abrir o aspectos nuevos.
class ProfileAvatar extends ConsumerWidget {
  final double size;
  final bool badge;
  const ProfileAvatar({super.key, this.size = 36, this.badge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final attention = badge &&
        (ref.watch(availableBoxesProvider) > 0 ||
            ref.watch(unseenSkinsProvider).isNotEmpty);
    final photo = profile.photoPath;
    final hasPhoto = photo != null && File(photo).existsSync();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: hasPhoto
                  ? Image.file(
                      File(photo),
                      fit: BoxFit.cover,
                      cacheWidth: (size * 3).round(),
                      errorBuilder: (_, __, ___) => _fallback(theme, profile),
                    )
                  : _fallback(theme, profile),
            ),
          ),
          if (attention)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF453A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(ThemeData theme, Profile profile) {
    final initial = profile.name.isEmpty ? null : profile.name[0].toUpperCase();
    return ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: initial == null
            ? Icon(Icons.person_rounded,
                size: size * 0.6, color: theme.colorScheme.onPrimaryContainer)
            : Text(
                initial,
                style: TextStyle(
                  fontSize: size * 0.46,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Los aspectos nuevos se marcan como vistos unos segundos después de
    // entrar, para que alcance a verse la etiqueta "Nuevo".
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) ref.read(rewardsProvider.notifier).markAllSeen();
    });
  }

  Future<void> _pickPhoto() async {
    final allowed = await ensureGalleryPermission(context);
    if (!allowed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(profileProvider.notifier);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 85,
      );
      if (picked == null) return;
      await notifier.setPhoto(picked);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo cargar la foto')),
      );
    }
  }

  final _shotKey = GlobalKey();

  /// Convierte la parte de arriba del perfil en una imagen y abre el menú de
  /// compartir (WhatsApp, Instagram, etc.).
  Future<void> _shareProfile() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary =
          _shotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'mi_perfil_bolsillo.png'));
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Mi colección en Bolsillo, la app de gastos gratis y de código abierto.',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo crear la imagen')),
      );
    }
  }

  Future<void> _redeem() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Canjear código'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Pega aquí tu código de aspecto único (BLS.…)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || !mounted) return;
    final message = await ref.read(rewardsProvider.notifier).redeem(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editTexts() async {
    final profile = ref.read(profileProvider);
    final name = TextEditingController(text: profile.name);
    final bio = TextEditingController(text: profile.bio);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tu perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              maxLength: 24,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bio,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Una frase sobre ti (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final newName = name.text;
    final newBio = bio.text;
    name.dispose();
    bio.dispose();
    if (save == true) {
      await ref
          .read(profileProvider.notifier)
          .setTexts(name: newName, bio: newBio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final seconds = ref.watch(usageProvider);
    final progress = ref.watch(boxProgressProvider);
    final available = ref.watch(availableBoxesProvider);
    final rewards = ref.watch(rewardsProvider);
    final stats = ref.watch(skinStatsProvider);
    final unused = ref.watch(unusedSkinsProvider);
    final owned = [
      for (final s in kAllSkins)
        if (rewards.owned.contains(s.id)) s,
    ];
    final fresh = rewards.owned.difference(rewards.seen);

    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                children: [
                  Icon(icon, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(height: 6),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          RepaintBoundary(
            key: _shotKey,
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                children: [
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: const ProfileAvatar(size: 104),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.photo_camera_rounded,
                            size: 18, color: theme.colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _editTexts,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.name.isEmpty ? 'Ponle nombre a tu perfil' : profile.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_rounded, size: 18),
                    ],
                  ),
                  if (profile.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(profile.bio,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat(Icons.timer_outlined, formatSeconds(seconds), 'En la app'),
              const SizedBox(width: 10),
              stat(Icons.inventory_2_outlined, '${rewards.boxesOpened}',
                  'Cajas abiertas'),
              const SizedBox(width: 10),
              stat(Icons.auto_awesome_outlined, '${owned.length}', 'Aspectos'),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Colección',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        '${owned.length}/${kAllSkins.length}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: owned.length / kAllSkins.length,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    owned.length == kAllSkins.length
                        ? '¡Los tienes todos!'
                        : 'Te faltan ${kAllSkins.length - owned.length} aspectos.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareProfile,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Compartir perfil'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  ),
                  icon: const Icon(Icons.leaderboard_rounded),
                  label: const Text('Amigos'),
                ),
              ),
            ],
          ),
          if (profile.photoPath != null)
            Center(
              child: TextButton(
                onPressed: () => ref.read(profileProvider.notifier).clearPhoto(),
                child: const Text('Quitar foto'),
              ),
            ),
          const SizedBox(height: 24),
          Text('Inventario',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 30,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$available ${available == 1 ? 'caja' : 'cajas'}',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              available == 1
                                  ? 'sin abrir'
                                  : 'sin abrir (se acumulan)',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Próxima caja en ${progress.remaining ~/ 60} min '
                    '${(progress.remaining % 60).toString().padLeft(2, '0')} s',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RewardsScreen()),
                      ),
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: Text(available > 0 ? 'Abrir cajas' : 'Ver recompensas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (unused.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        unused.length == 1
                            ? 'Aún no usas "${unused.first.name}". Pruébalo en Tarjetas → personalizar.'
                            : 'Tienes ${unused.length} aspectos sin estrenar. Pruébalos en Tarjetas → personalizar.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Tus aspectos (${owned.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: _redeem,
                icon: const Icon(Icons.redeem_rounded, size: 18),
                label: const Text('Canjear código'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (owned.isEmpty)
            Text(
              'Todavía no tienes ninguno. Abre tu primera caja para empezar.',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in owned)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SkinTile(
                        skin: s,
                        width: 150,
                        onTap: () => showSkinDetails(
                          context,
                          s,
                          owned: true,
                          stat: stats[s.id],
                          serial: rewards.serials[s.id],
                        ),
                      ),
                      if (fresh.contains(s.id))
                        Positioned(
                          right: -4,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF453A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Nuevo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
