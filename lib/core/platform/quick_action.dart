import 'package:flutter/services.dart';

const _channel = MethodChannel('com.davidcontabilidad.app_contabilidad/quick_action');

/// Pregunta a Android si el usuario llegó desde un botón del panel de
/// ajustes rápidos. Devuelve "expense", "income" o null. Solo se entrega una
/// vez por toque.
Future<String?> consumeQuickAction() async {
  try {
    return await _channel.invokeMethod<String>('consume');
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
