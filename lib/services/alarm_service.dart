import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/alarm_model.dart';

class AlarmService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final Set<String> _shownAlarms = <String>{};

  static Future<void> initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> scheduleAlarm(Alarm alarm) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('alarms')
          .doc(alarm.id)
          .set(alarm.toMap());

      if (alarm.isActive && alarm.alarmDateTime.isAfter(DateTime.now())) {
        await _scheduleLocalNotification(alarm);
      }
    } catch (e) {
      print('Error scheduling alarm: $e');
    }
  }

  static Future<void> _scheduleLocalNotification(Alarm alarm) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarmas de Granja',
      channelDescription: 'Notificaciones para alarmas de animales',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      alarm.title,
      alarm.description,
      tz.TZDateTime.from(alarm.alarmDateTime, tz.local),
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Stream<List<Alarm>> getAlarmsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('alarms')
        .orderBy('alarmDateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Alarm.fromMap(doc.data()))
        .toList());
  }

  static Future<void> deleteAlarm(String alarmId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('alarms')
          .doc(alarmId)
          .delete();

      await _notifications.cancel(alarmId.hashCode);
      _shownAlarms.remove(alarmId);
    } catch (e) {
      print('Error deleting alarm: $e');
    }
  }

  static Future<void> toggleAlarm(String alarmId, bool isActive) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('alarms')
          .doc(alarmId)
          .update({'isActive': isActive});

      if (!isActive) {
        await _notifications.cancel(alarmId.hashCode);
        _shownAlarms.remove(alarmId);
      }
    } catch (e) {
      print('Error toggling alarm: $e');
    }
  }

  // Nuevo método para verificar y mostrar alarmas
  static bool shouldShowAlarm(Alarm alarm) {
    final now = DateTime.now();
    final alarmTime = alarm.alarmDateTime;

    // Solo mostrar si la alarma está activa y es dentro de los próximos 30 segundos
    final shouldShow = alarm.isActive &&
        alarmTime.isAfter(now) &&
        alarmTime.isBefore(now.add(const Duration(seconds: 1))) &&
        !_shownAlarms.contains(alarm.id);

    if (shouldShow) {
      _shownAlarms.add(alarm.id);
    }

    return shouldShow;
  }

  // Método para marcar alarma como mostrada
  static void markAlarmAsShown(String alarmId) {
    _shownAlarms.add(alarmId);
  }

  // Método para limpiar alarmas antiguas
  static void cleanOldAlarms() {
    final now = DateTime.now();
    _shownAlarms.removeWhere((alarmId) {
      // Aquí podrías implementar lógica para limpiar alarmas muy antiguas
      return true; // Por ahora limpiamos todas
    });
  }
}