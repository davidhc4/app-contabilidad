import 'package:flutter/material.dart';

/// Muestra una ventana con barra de carga mientras se ejecuta [task] y la
/// cierra sola al terminar (o si falla). Devuelve lo que devuelva [task].
Future<T> runWithProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() task,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
  );
  // Un mínimo de tiempo para que la barra se alcance a ver.
  final minimum = Future<void>.delayed(const Duration(milliseconds: 600));
  try {
    final result = await task();
    await minimum;
    return result;
  } finally {
    if (navigator.mounted) navigator.pop();
  }
}
