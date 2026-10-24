import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/platform/gallery_permission.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import '../rewards/rewards_state.dart';
import '../rewards/skin_widgets.dart';
import '../rewards/skins.dart';
import '../theme/halloween.dart';
import '../../shared/widgets/bank_card_widget.dart';
import 'card_style.dart';

/// Crear una tarjeta nueva, o editar/personalizar una existente si se pasa
/// [editing] (dato 100% local, el usuario la crea a mano).
Future<void> showCardFormSheet(BuildContext context, {CardItem? editing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CardFormSheet(editing: editing),
  );
}

class CardFormSheet extends ConsumerStatefulWidget {
  final CardItem? editing;
  const CardFormSheet({super.key, this.editing});

  @override
  ConsumerState<CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends ConsumerState<CardFormSheet> {
  late final _nameController =
      TextEditingController(text: widget.editing?.name ?? '');
  late final _digitsController =
      TextEditingController(text: widget.editing?.lastFourDigits ?? '');
  late String _network = widget.editing?.network ?? CardNetwork.visa;
  late final List<String> _gradient = _initialGradient();

  late final _balanceController = TextEditingController();
  String? _photoPath;
  String? _sticker;
  String? _skin;
  String? _startSkin;
  // Foto elegida en esta sesión que todavía no se guardó (se borra si el
  // usuario la cambia o cierra sin guardar).
  String? _pendingPhoto;
  bool _saved = false;
  late final CardStylesNotifier _styles;
  // 0 = mujer, 1 = hombre, 2 = Halloween
  int _stickerSet = 0;
  bool _saving = false;

  List<String> _initialGradient() {
    final e = widget.editing;
    if (e == null) return [kCardStart, kCardEnd];
    return [e.colorStart, e.colorEnd];
  }

  @override
  void initState() {
    super.initState();
    _styles = ref.read(cardStylesProvider.notifier);
    final e = widget.editing;
    if (e != null) {
      final style = ref.read(cardStylesProvider)[e.id] ?? CardStyle.empty;
      _photoPath = style.photoPath;
      _sticker = style.sticker;
      _skin = style.skin;
      _startSkin = style.skin;
      _stickerSet = kStickersHalloween.contains(style.sticker)
          ? 2
          : (kStickersHombre.contains(style.sticker) ? 1 : 0);
      final initial = style.initialBalance;
      if (initial != null && initial > 0) {
        _balanceController.text = formatThousands(initial.round().toString());
      }
    }
  }

  @override
  void dispose() {
    final pending = _pendingPhoto;
    if (!_saved && pending != null) {
      _styles.discardPhoto(pending);
    }
    _nameController.dispose();
    _digitsController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // 1) Permiso de acceso a las fotos (sin él no se puede continuar).
    final allowed = await ensureGalleryPermission(context);
    if (!allowed || !mounted) return;

    final styles = ref.read(cardStylesProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      // 2) Se guarda de una vez en la carpeta de la app para que la foto
      // siga existiendo cuando se toque "Guardar".
      final saved = await styles.savePickedPhoto(
        picked,
        widget.editing?.id ?? 'nueva',
      );
      final previousPending = _pendingPhoto;
      if (previousPending != null) await styles.discardPhoto(previousPending);
      if (!mounted) return;
      setState(() {
        _photoPath = saved;
        _pendingPhoto = saved;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo cargar la foto: ${_short(e)}')),
      );
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final digits = _digitsController.text.trim();
    if (name.isEmpty || digits.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el nombre y los 4 últimos dígitos'),
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final repo = ref.read(cardRepositoryProvider);
    final styles = ref.read(cardStylesProvider.notifier);
    final editing = widget.editing;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final String cardId;
      if (editing == null) {
        cardId = await repo.addCard(
          name: name,
          lastFourDigits: digits,
          network: _network,
          colorStart: _gradient[0],
          colorEnd: _gradient[1],
        );
      } else {
        cardId = editing.id;
        await repo.updateCard(
          id: cardId,
          name: name,
          lastFourDigits: digits,
          network: _network,
          colorStart: _gradient[0],
          colorEnd: _gradient[1],
        );
      }

      await styles.setStyle(
        cardId,
        CardStyle(
          photoPath: _photoPath,
          sticker: _sticker,
          skin: _skin,
          initialBalance: parseThousands(_balanceController.text)?.toDouble(),
        ),
      );
      _saved = true;
      final applied = _skin;
      if (applied != null && applied != _startSkin && mounted) {
        ref.read(skinStatsProvider.notifier).noteApplied(applied);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo guardar la tarjeta: ${_short(e)}')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(rewardsProvider).owned;
    final ownedSkins = [
      for (final k in [...kSkins, ...kExtraSkins])
        if (owned.contains(k.id)) k,
    ];
    final isEditing = widget.editing != null;
    final halloween = ref.watch(halloweenProvider);
    final set = (_stickerSet == 2 && !halloween) ? 0 : _stickerSet;
    final stickers = switch (set) {
      2 => kStickersHalloween,
      1 => kStickersHombre,
      _ => kStickersMujer,
    };
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    final hintStyle = Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Personalizar tarjeta' : 'Nueva tarjeta',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            // Vista previa en vivo de cómo va quedando.
            BankCardView(
              name: _nameController.text.trim().isEmpty
                  ? 'Nombre de la tarjeta'
                  : _nameController.text.trim(),
              lastFourDigits:
                  _digitsController.text.isEmpty ? '0000' : _digitsController.text,
              network: _network,
              colorStart: _gradient[0],
              colorEnd: _gradient[1],
              style: CardStyle(photoPath: _photoPath, sticker: _sticker, skin: _skin),
              balance: parseThousands(_balanceController.text)?.toDouble() ??
                  (widget.editing == null ? 0.0 : null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nombre de la tarjeta',
                hintText: 'Ej. Nu Mastercard',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _digitsController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Últimos 4 dígitos',
                hintText: 'Ej. 1234',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Dinero que ya tiene (opcional)',
                prefixText: r'$ ',
                helperText: 'Para que el saldo de la tarjeta sea el real. '
                    'Déjalo vacío si empieza en cero.',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text('Red de la tarjeta', style: labelStyle),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: CardNetwork.visa, label: Text('Visa')),
                ButtonSegment(
                    value: CardNetwork.mastercard, label: Text('Mastercard')),
                ButtonSegment(value: CardNetwork.other, label: Text('Otra')),
              ],
              selected: {_network},
              onSelectionChanged: (s) => setState(() => _network = s.first),
            ),
            const SizedBox(height: 16),
            Text('Aspectos especiales', style: labelStyle),
            const SizedBox(height: 2),
            Text(
              ownedSkins.isEmpty
                  ? 'Todavía no tienes ninguno. Los ganas con las cajas que '
                      'llegan por usar la app (Perfil → Inventario).'
                  : 'Los ganas abriendo cajas. Toca uno para ponerlo.',
              style: hintStyle,
            ),
            if (ownedSkins.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _SkinChoice(
                      selected: _skin == null,
                      onTap: () => setState(() => _skin = null),
                      child: const _NoSkinTile(),
                    ),
                    for (final k in ownedSkins)
                      _SkinChoice(
                        selected: _skin == k.id,
                        onTap: () => setState(() => _skin = k.id),
                        child: SkinTile(skin: k, width: 132),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('Foto de fondo', style: labelStyle),
            const SizedBox(height: 2),
            Text('Usa una foto de tu galería como fondo de la tarjeta.',
                style: hintStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(_photoPath == null
                        ? 'Elegir de mi galería'
                        : 'Cambiar foto'),
                  ),
                ),
                if (_photoPath != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final pending = _pendingPhoto;
                      if (pending != null) {
                        ref.read(cardStylesProvider.notifier).discardPhoto(pending);
                      }
                      setState(() {
                        _photoPath = null;
                        _pendingPhoto = null;
                      });
                    },
                    icon: const Icon(Icons.hide_image_outlined),
                    label: const Text('Quitar'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Text('Sticker', style: labelStyle),
            const SizedBox(height: 2),
            Text('Elige una pegatina para decorar la tarjeta.', style: hintStyle),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(
                  value: 0,
                  label: Text('Mujer'),
                  icon: Icon(Icons.female_rounded),
                ),
                const ButtonSegment(
                  value: 1,
                  label: Text('Hombre'),
                  icon: Icon(Icons.male_rounded),
                ),
                if (halloween)
                  const ButtonSegment(
                    value: 2,
                    label: Text('Halloween'),
                    icon: Icon(Icons.pest_control_rounded),
                  ),
              ],
              selected: {set},
              onSelectionChanged: (s) => setState(() => _stickerSet = s.first),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StickerOption(
                  selected: _sticker == null,
                  onTap: () => setState(() => _sticker = null),
                  child: const Icon(Icons.block_rounded, size: 22),
                ),
                ...stickers.map(
                  (s) => _StickerOption(
                    selected: _sticker == s,
                    onTap: () => setState(() => _sticker = s),
                    child: Text(s, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: Icon(isEditing ? Icons.check_rounded : Icons.add_card_rounded),
              label: Text(isEditing ? 'Guardar cambios' : 'Crear tarjeta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerOption extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _StickerOption({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? primary.withValues(alpha: 0.15) : null,
          border: Border.all(
            color: selected ? primary : Colors.grey.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Recorta mensajes de error muy largos para que quepan en pantalla.
String _short(Object e) {
  final text = e.toString();
  return text.length > 120 ? '${text.substring(0, 120)}…' : text;
}

/// Marco que resalta el aspecto elegido.
class _SkinChoice extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _SkinChoice({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: IgnorePointer(child: child),
        ),
      ),
    );
  }
}

class _NoSkinTile extends StatelessWidget {
  const _NoSkinTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block_rounded, size: 26),
          SizedBox(height: 6),
          Text('Ninguno',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
