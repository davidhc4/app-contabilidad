import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import 'update_service.dart';

enum _Step { idle, checking, upToDate, available, downloading, ready, error }

/// Tarjeta de Ajustes para buscar actualizaciones: consulta la última
/// versión publicada en GitHub, descarga el APK y abre el instalador de
/// Android. La app solo se conecta a internet cuando se toca el botón.
class UpdateSection extends StatefulWidget {
  const UpdateSection({super.key});

  @override
  State<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<UpdateSection>
    with WidgetsBindingObserver {
  _Step _step = _Step.idle;
  UpdateInfo? _info;
  File? _file;
  double _progress = 0;
  String _error = '';

  // Se fue a los ajustes de Android a dar el permiso de instalar; al volver
  // se continúa solo.
  bool _waitingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingPermission) {
      _waitingPermission = false;
      _continueAfterPermission();
    }
  }

  Future<void> _continueAfterPermission() async {
    final file = _file;
    if (file == null || !mounted) return;
    if (await canInstallUpdates()) await _install(file);
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _step = _Step.error;
      _error = e is UpdateException ? e.message : 'Algo falló: $e';
    });
  }

  Future<void> _check() async {
    setState(() => _step = _Step.checking);
    try {
      final info = await fetchLatestRelease();
      if (!mounted) return;
      if (!info.isNewer) {
        await clearDownloads();
        if (!mounted) return;
        setState(() {
          _info = info;
          _step = _Step.upToDate;
        });
        return;
      }
      if (info.url == null) {
        throw UpdateException(
            'La versión ${info.version} todavía se está publicando. Intenta en unos minutos.');
      }
      setState(() {
        _info = info;
        _step = _Step.available;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _download() async {
    final info = _info;
    if (info == null) return;
    setState(() {
      _step = _Step.downloading;
      _progress = 0;
    });
    try {
      final file = await downloadUpdate(info, (value) {
        if (mounted) setState(() => _progress = value);
      });
      if (!mounted) return;
      setState(() {
        _file = file;
        _step = _Step.ready;
      });
      await _install(file);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _install(File file) async {
    try {
      if (!await canInstallUpdates()) {
        if (!mounted) return;
        final go = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Falta un permiso'),
            content: const Text(
              'Para instalar la actualización, Android necesita que le '
              'permitas a Bolsillo instalar apps. En la pantalla que se abre, '
              'activa "Permitir desde esta fuente" y vuelve atrás: la '
              'instalación continúa sola.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Abrir ajustes'),
              ),
            ],
          ),
        );
        if (go == true) {
          _waitingPermission = true;
          await openInstallPermission();
        }
        return;
      }
      await installUpdate(file);
    } catch (e) {
      _fail(e);
    }
  }

  String _megas(int bytes) => '${(bytes / (1024 * 1024)).round()} MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _info;
    final file = _file;

    final status = switch (_step) {
      _Step.idle => 'Tienes la versión $kAppVersion.',
      _Step.checking => 'Buscando la última versión…',
      _Step.upToDate => 'Tienes la última versión ($kAppVersion).',
      _Step.available => 'Hay una versión nueva: ${info?.version}. '
          'Tú tienes la $kAppVersion.',
      _Step.downloading =>
        'Descargando la versión ${info?.version}… ${(_progress * 100).round()} %',
      _Step.ready => 'La versión ${info?.version} está lista para instalar. '
          'Tus datos se conservan.',
      _Step.error => _error,
    };

    final busy = _step == _Step.checking || _step == _Step.downloading;

    var label = 'Buscar actualizaciones';
    var icon = Icons.refresh_rounded;
    VoidCallback action = _check;
    if (_step == _Step.available) {
      label = info != null && info.size > 0
          ? 'Descargar e instalar (${_megas(info.size)})'
          : 'Descargar e instalar';
      icon = Icons.download_rounded;
      action = _download;
    } else if (_step == _Step.ready && file != null) {
      label = 'Instalar actualización';
      icon = Icons.system_update_rounded;
      action = () => _install(file);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            status,
            style: _step == _Step.error
                ? theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error)
                : theme.textTheme.bodyMedium,
          ),
          if (_step == _Step.downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: busy ? null : action,
            icon: _step == _Step.checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon),
            label: Text(label),
          ),
        ],
      ),
    );
  }
}
