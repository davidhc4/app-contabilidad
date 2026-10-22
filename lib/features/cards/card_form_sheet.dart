import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/platform/gallery_permission.dart';
import '../../core/utils/icon_map.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
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

/// Paleta de gradientes predefinidos para elegir, al estilo de la paleta de
/// colores de categorías.
const _gradients = <List<String>>[
  ['FF0A84FF', 'FF64D2FF'], // azul
  ['FF30D158', 'FF63E6E2'], // verde
  ['FFBF5AF2', 'FFFF375F'], // morado-rosa
  ['FFFF9F0A', 'FFFF453A'], // naranja-rojo
  ['FF1C1C1E', 'FF636366'], // negro/gris (estilo Nu)
  ['FFFFD60A', 'FF30D158'], // amarillo-verde (estilo Lemon)
  ['FFFF6FB5', 'FFFFB3D9'], // rosado pastel
  ['FF3A7BD5', 'FF3A6073'], // azul oscuro
];

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
  late List<String> _gradient = _initialGradient();

  late final _balanceController = TextEditingController();
  String? _photoPath;
  String? _sticker;
  // Foto elegida en esta sesión que todavía no se guardó (se borra si el
  // usuario la cambia o cierra sin guardar).
  String? _pendingPhoto;
  bool _saved = false;
  late final CardStylesNotifier _styles;
  bool _stickersMujer = true;
  bool _saving = false;

  List<String> _initialGradient() {
    final e = widget.editing;
    if (e == null) return _gradients.first;
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
      _stickersMujer = !kStickersHombre.contains(style.sticker);
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
          initialBalance: parseThousands(_balanceController.text)?.toDouble(),
        ),
      );
      _saved = true;
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
    final isEditing = widget.editing != null;
    final stickers = _stickersMujer ? kStickersMujer : kStickersHombre;
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
              style: CardStyle(photoPath: _photoPath, sticker: _sticker),
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
            Text('Color de fondo', style: labelStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _gradients.map((g) {
                final selected = g[0] == _gradient[0] && g[1] == _gradient[1];
                return GestureDetector(
                  onTap: () => setState(() => _gradient = g),
                  child: Container(
                    width: 44,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorFromHex(g[0]), colorFromHex(g[1])],
                      ),
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
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
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Mujer'),
                  icon: Icon(Icons.female_rounded),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Hombre'),
                  icon: Icon(Icons.male_rounded),
                ),
              ],
              selected: {_stickersMujer},
              onSelectionChanged: (s) =>
                  setState(() => _stickersMujer = s.first),
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
