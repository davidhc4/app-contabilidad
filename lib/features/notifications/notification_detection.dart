import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import '../../data/local/tables.dart';

const _channel = MethodChannel('com.davidcontabilidad.app_contabilidad/notif');
const _enabledKey = 'notif_pagos';

/// Un posible pago detectado en una notificación.
class PaymentCandidate {
  /// Monto detectado.
  final double amount;

  /// true si parece un ingreso (entró dinero); false si parece un gasto.
  final bool isIncome;

  /// Descripción sugerida (de dónde salió).
  final String description;

  const PaymentCandidate({
    required this.amount,
    required this.isIncome,
    required this.description,
  });

  String get type => isIncome ? TxType.income : TxType.expense;
}

const _incomeWords = [
  'recibiste', 'recibió', 'recibio', 'recarga', 'recargaste', 'abono',
  'abonaron', 'consignación', 'consignacion', 'te enviaron', 'te envió',
  'te envio', 'transferencia recibida', 'entró', 'entro', 'ingreso',
  'devolución', 'devolucion', 'reembolso', 'nómina', 'nomina', 'pago recibido',
];

const _expenseWords = [
  'compra', 'compraste', 'pagaste', 'pago por', 'débito', 'debito',
  'retiro', 'retiraste', 'enviaste', 'transferiste', 'cobro', 'cargo',
  'avance', 'salida', 'gastaste',
];

/// Extrae el monto de un texto en formato colombiano ("$ 50.000", "50.000").
double? parseAmount(String text) {
  final match = RegExp(r'\$?\s?(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+[.,]\d{2})')
      .firstMatch(text);
  if (match == null) return null;
  var raw = match.group(1)!;
  // Si el último separador tiene 1-2 dígitos, son decimales; si son 3, miles.
  final lastSep = raw.lastIndexOf(RegExp(r'[.,]'));
  if (lastSep >= 0 && raw.length - lastSep - 1 <= 2) {
    final intPart = raw.substring(0, lastSep).replaceAll(RegExp(r'[.,]'), '');
    final dec = raw.substring(lastSep + 1);
    return double.tryParse('$intPart.$dec');
  }
  return double.tryParse(raw.replaceAll(RegExp(r'[.,]'), ''));
}

/// Analiza una notificación y, si parece un pago, devuelve el candidato.
PaymentCandidate? parseNotification(String title, String text) {
  final blob = '$title $text';
  final amount = parseAmount(blob);
  if (amount == null || amount <= 0) return null;
  final lower = blob.toLowerCase();
  final isIncome = _incomeWords.any(lower.contains) &&
      !_expenseWords.any(lower.contains);
  // La descripción: el título si sirve, si no un trozo del texto.
  var desc = title.trim();
  if (desc.isEmpty || desc.length > 40) {
    desc = text.trim();
  }
  if (desc.length > 60) desc = '${desc.substring(0, 57)}…';
  return PaymentCandidate(
    amount: amount,
    isIncome: isIncome,
    description: desc,
  );
}

/// Si la función está activada (preferencia guardada en el teléfono).
class NotifEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final saved = await LocalStore.getString(_enabledKey);
    final on = saved == '1';
    state = on;
    await _syncNative(on);
  }

  Future<void> _syncNative(bool on) async {
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': on});
    } on PlatformException {
      // Solo existe en Android.
    } on MissingPluginException {
      // No disponible.
    }
  }

  Future<void> set(bool on) async {
    state = on;
    await LocalStore.setString(_enabledKey, on ? '1' : '0');
    await _syncNative(on);
  }
}

final notifEnabledProvider =
    NotifierProvider<NotifEnabledNotifier, bool>(NotifEnabledNotifier.new);

/// Si Android le dio a la app acceso a las notificaciones.
Future<bool> notifAccessGranted() async {
  try {
    return await _channel.invokeMethod<bool>('isAccessGranted') ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

/// Abre la pantalla de Android "Acceso a las notificaciones".
Future<void> openNotifAccessSettings() async {
  try {
    await _channel.invokeMethod('openAccessSettings');
  } on PlatformException {
    // Nada que hacer.
  } on MissingPluginException {
    // Solo en Android.
  }
}

/// Saca de la cola los pagos detectados desde la última vez y la vacía.
Future<List<PaymentCandidate>> drainCandidates() async {
  String raw;
  try {
    raw = await _channel.invokeMethod<String>('drain') ?? '[]';
  } on PlatformException {
    return const [];
  } on MissingPluginException {
    return const [];
  }
  try {
    final list = jsonDecode(raw) as List;
    final out = <PaymentCandidate>[];
    for (final e in list) {
      if (e is! Map) continue;
      final c = parseNotification(
        (e['title'] as String?) ?? '',
        (e['text'] as String?) ?? '',
      );
      if (c != null) out.add(c);
    }
    return out;
  } catch (_) {
    return const [];
  }
}
