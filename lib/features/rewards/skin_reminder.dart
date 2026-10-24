import 'dart:math' as math;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorio local (sin internet) para quien ganó un aspecto y todavía no
/// lo ha puesto en ninguna tarjeta. Se programa para un momento al azar
/// entre 8 y 48 horas después de salir de la app, en horario de día, y se
/// cancela al volver a entrar.
class SkinReminder {
  SkinReminder._();

  static const _id = 7001;
  static final _rng = math.Random();
  static bool _ready = false;

  static Future<void> cancel() async {
    try {
      await FlutterLocalNotificationsPlugin().cancel(_id);
    } catch (_) {
      // Un recordatorio que no se cancela no es grave.
    }
  }

  static DateTime _randomMoment() {
    var when = DateTime.now().add(Duration(minutes: 480 + _rng.nextInt(2400)));
    if (when.hour < 10 || when.hour >= 21) {
      final day = when.hour >= 21 ? when.add(const Duration(days: 1)) : when;
      when = DateTime(day.year, day.month, day.day, 10 + _rng.nextInt(10),
          _rng.nextInt(60));
    }
    return when;
  }

  static Future<void> schedule(List<String> unusedNames) async {
    if (unusedNames.isEmpty) return cancel();
    try {
      if (!_ready) {
        tzdata.initializeTimeZones();
        _ready = true;
      }
      final body = unusedNames.length == 1
          ? 'Aún no utilizas el aspecto que desbloqueaste: '
              '"${unusedNames.first}". Pruébalo ahora en tus tarjetas.'
          : 'Tienes ${unusedNames.length} aspectos sin estrenar. '
              'Pruébalos ahora en tus tarjetas.';
      await FlutterLocalNotificationsPlugin().zonedSchedule(
        _id,
        'Tienes un aspecto sin estrenar',
        body,
        tz.TZDateTime.from(_randomMoment(), tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'aspectos',
            'Aspectos y recompensas',
            channelDescription: 'Avisos sobre tus aspectos y tus cajas',
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Si el teléfono no deja programar avisos, simplemente no se envía.
    }
  }
}
