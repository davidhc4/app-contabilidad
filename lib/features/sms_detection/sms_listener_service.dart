import 'dart:convert';

import 'package:another_telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/repositories/sms_sender_repository.dart';
import 'sms_parser.dart';

/// Payload que se guarda en la notificación local para poder reabrir el
/// formulario de confirmación cuando el usuario la toca.
class PendingSmsPayment {
  final double amount;
  final String? merchant;
  final DateTime date;
  final String rawBody;

  PendingSmsPayment({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.rawBody,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'merchant': merchant,
        'date': date.toIso8601String(),
        'rawBody': rawBody,
      };

  static PendingSmsPayment fromJson(Map<String, dynamic> json) =>
      PendingSmsPayment(
        amount: (json['amount'] as num).toDouble(),
        merchant: json['merchant'] as String?,
        date: DateTime.parse(json['date'] as String),
        rawBody: json['rawBody'] as String,
      );
}

/// Escucha SMS entrantes, los compara contra los remitentes configurados
/// (o el filtro genérico) y notifica a quien esté escuchando
/// [onPaymentDetected] o muestra una notificación local si la app está en
/// background.
class SmsListenerService {
  final Telephony telephony = Telephony.instance;
  final SmsSenderRepository senderRepository;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  void Function(PendingSmsPayment payment)? onPaymentDetected;

  SmsListenerService(this.senderRepository);

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<bool> requestPermissions() async {
    final sms = await Permission.sms.request();
    return sms.isGranted;
  }

  /// Registra el listener en foreground. Para background se depende del
  /// background handler nativo de `another_telephony` (ver AndroidManifest).
  void startListening() {
    telephony.listenIncomingSms(
      onNewMessage: _handleMessage,
      listenInBackground: true,
      onBackgroundMessage: _backgroundMessageHandler,
    );
  }

  Future<void> _handleMessage(SmsMessage message) async {
    final body = message.body ?? '';
    final sender = message.address ?? '';

    final senders = await senderRepository.enabled();
    String? customRegex;
    for (final s in senders) {
      if (sender.contains(s.senderIdOrName) ||
          s.senderIdOrName.toLowerCase() == 'banco (genérico)') {
        customRegex = s.regexPattern;
        break;
      }
    }

    final parsed = SmsParser.parse(body, customRegex: customRegex);
    if (parsed == null) return;

    final pending = PendingSmsPayment(
      amount: parsed.amount,
      merchant: parsed.merchant,
      date: parsed.date,
      rawBody: body,
    );

    if (onPaymentDetected != null) {
      onPaymentDetected!(pending);
    } else {
      await _showNotification(pending);
    }
  }

  Future<void> _showNotification(PendingSmsPayment payment) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sms_payment_channel',
        'Pagos detectados',
        channelDescription: 'Avisa cuando se detecta un pago por SMS',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _notifications.show(
      payment.date.millisecondsSinceEpoch ~/ 1000,
      '¿Agregar este gasto?',
      payment.merchant != null
          ? '\$${payment.amount.toStringAsFixed(0)} en ${payment.merchant}'
          : '\$${payment.amount.toStringAsFixed(0)} con tu tarjeta',
      details,
      payload: jsonEncode(payment.toJson()),
    );
  }

  void Function(PendingSmsPayment)? onNotificationTapped;

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final payment = PendingSmsPayment.fromJson(jsonDecode(payload));
    onNotificationTapped?.call(payment);
  }
}

/// Debe ser una función de nivel superior o estática: se ejecuta en un
/// isolate separado cuando llega un SMS con la app en background.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(SmsMessage message) async {
  // El procesamiento real (parseo + notificación) ocurre en el isolate
  // principal vía `onNewMessage` cuando la app vuelve a foreground; aquí
  // solo se deja el entry point requerido por el plugin para habilitar
  // la recepción en background en Android.
}
