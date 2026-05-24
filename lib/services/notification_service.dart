import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _enabledKey = 'notifications_enabled';
  static const _minutesKey = 'notifications_minutes';
  static const _channelId = 'appointment_reminders';
  static const _channelName = 'Randevu Hatırlatmaları';

  static const List<int> minuteOptions = [10, 15, 30, 60, 120];

  static Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) await _plugin.cancelAll();
  }

  static Future<int> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minutesKey) ?? 30;
  }

  static Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minutesKey, minutes);
  }

  static String labelFor(int minutes) {
    if (minutes < 60) return '$minutes dakika önce';
    final h = minutes ~/ 60;
    return '$h saat önce';
  }

  static int _notifId(String appointmentId) =>
      appointmentId.hashCode.abs() % 100000;

  static Future<void> scheduleReminder({
    required String appointmentId,
    required String barberName,
    required DateTime scheduledAt,
  }) async {
    if (!await isEnabled()) return;

    final minutes = await getReminderMinutes();
    final reminderTime = scheduledAt.subtract(Duration(minutes: minutes));
    if (reminderTime.isBefore(DateTime.now())) return;

    final utc = reminderTime.toUtc();
    final tzTime = tz.TZDateTime.utc(
        utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);

    await _plugin.zonedSchedule(
      _notifId(appointmentId),
      'Randevu Hatırlatması',
      '$barberName randevunuz ${labelFor(minutes)} başlayacak',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(String appointmentId) async {
    await _plugin.cancel(_notifId(appointmentId));
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
