import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// IDs fijos de las notificaciones programadas (una por franja horaria).
const idRecordatorioManana = 1;
const idRecordatorioNoche = 2;

final _patronVibracion = Int64List.fromList([0, 500, 250, 500, 250, 500]);

class NotificacionesService {
  static final NotificacionesService instance = NotificacionesService._internal();
  NotificacionesService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  Future<void> init() async {
    if (_inicializado) return;
    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _inicializado = true;
  }

  Future<void> solicitarPermisos() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // Permiso de "Alarmas y recordatorios" (Android 12+), necesario para que
    // la alarma suene exactamente a la hora elegida y no con retraso.
    await android?.requestExactAlarmsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> programarRecordatorioDiario({
    required int id,
    required TimeOfDay hora,
    required String titulo,
    required String cuerpo,
  }) async {
    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      _proximaInstancia(hora),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'respiracion_alarma',
          'Alarma de respiración',
          channelDescription: 'Alarma diaria para practicar la respiración guiada',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _patronVibracion,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelar(int id) async {
    await _plugin.cancel(id);
  }

  tz.TZDateTime _proximaInstancia(TimeOfDay hora) {
    final ahora = tz.TZDateTime.now(tz.local);
    var programada = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, hora.hour, hora.minute);
    if (programada.isBefore(ahora)) {
      programada = programada.add(const Duration(days: 1));
    }
    return programada;
  }
}
