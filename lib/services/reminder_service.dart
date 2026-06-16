import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class ReminderService {
  static const _prefix = 'reminder_';
  static const _channelId = 'medistock_reminders';
  static const _channelName = 'Rappels de prise';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    // Sur le web, pas de notifications natives : on ne fait rien.
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: 'Rappels pour prendre vos médicaments',
              importance: Importance.high,
            ),
          );
    }
    _initialized = true;
  }

  static Future<bool> _requestPermission() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result == true;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted == true;
    }
    return true;
  }

  /// Id de notification natif (int) dérivé de l'id Firestore (String), stable pour un id donné.
  static int _notifId(String id) => id.hashCode & 0x7FFFFFFF;

  static Future<String?> getReminderTime(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$id');
  }

  static Future<void> setReminderTime(String id, String timeHHmm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$id', timeHHmm);
  }

  static Future<void> clearReminder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
    if (!kIsWeb) await _plugin.cancel(_notifId(id));
  }

  /// Schedules a daily notification at timeHHmm (e.g. "08:00"). medicationName for the body.
  static Future<void> scheduleReminder(String medicationId, String timeHHmm, String medicationName) async {
    await setReminderTime(medicationId, timeHHmm);
    if (kIsWeb) return;
    await _requestPermission();
    final parts = timeHHmm.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Rappels pour prendre vos médicaments',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      _notifId(medicationId),
      'MediStock',
      'Prendre $medicationName',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Reschedules all reminders. Call after app load with list of (medicationId, name, timeHHmm).
  static Future<void> rescheduleAll(List<({String id, String name, String time})> items) async {
    for (final item in items) {
      await _plugin.cancel(_notifId(item.id));
    }
    await _requestPermission();
    final now = tz.TZDateTime.now(tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Rappels pour prendre vos médicaments',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final item in items) {
      final parts = item.time.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _notifId(item.id),
        'MediStock',
        'Prendre ${item.name}',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Returns all reminder times: medicationId (as string) -> "HH:mm".
  static Future<Map<String, String>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <String, String>{};
    for (final k in keys) {
      final v = prefs.getString(k);
      if (v != null) map[k.substring(_prefix.length)] = v;
    }
    return map;
  }
}
