import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';
import '../utils/time_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'schedule_scanner_alarms';
  static const String channelName = 'Schedule Scanner Alarms';
  static const String channelDescription =
      'High-priority alarms and reminders for classes, shifts, and duties';

  Future<void> initialize() async {
    // 1. Initialize timezone database and detect device location
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: Timezone detection fallback: $e');
    }

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Initialization Settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Linux / Windows settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // 5. Create Android Notification Channel
    final androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Calculates a stable, deterministic integer ID for notification cancellation.
  /// Uses FNV-1a 32-bit hash instead of Dart's hashCode, which is not guaranteed
  /// to produce the same value across different process runs.
  int _generateNotificationId(String entryId, int dayOfWeek, int leadMinutes) {
    final key = '$entryId-$dayOfWeek-$leadMinutes';
    // FNV-1a 32-bit hash
    var hash = 0x811c9dc5;
    for (final codeUnit in key.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    // Ensure positive and within signed 32-bit int range for Android
    return hash & 0x7FFFFFFF;
  }

  /// Schedules all reminders for a schedule entry across all selected weekdays
  Future<void> scheduleEntryReminders(ScheduleEntry entry) async {
    if (!entry.isActive) return;

    final startParts = entry.startTime.split(':');
    if (startParts.length != 2) return;

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);

    for (final dayOfWeek in entry.daysOfWeek) {
      for (final leadMinutes in entry.reminders) {
        final notificationId = _generateNotificationId(entry.id, dayOfWeek, leadMinutes);

        // Compute lead time offset
        int alarmHour = startHour;
        int alarmMinute = startMinute - leadMinutes;
        int alarmDay = dayOfWeek;

        while (alarmMinute < 0) {
          alarmMinute += 60;
          alarmHour -= 1;
        }
        if (alarmHour < 0) {
          alarmHour += 24;
          alarmDay = alarmDay == 1 ? 7 : alarmDay - 1; // Rolled back to previous day
        }

        final tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(
          alarmDay,
          alarmHour,
          alarmMinute,
        );

        final String reminderText = leadMinutes == 0
            ? 'Starting now at ${TimeUtils.formatTo12Hour(entry.startTime)}'
            : 'Starting in $leadMinutes minutes (${TimeUtils.formatTo12Hour(entry.startTime)})';

        final String locationText =
            entry.location != null && entry.location!.isNotEmpty
                ? ' • Location: ${entry.location}'
                : '';

        final String title = '⏰ ${entry.category.shortLabel}: ${entry.title}';
        final String body = '$reminderText$locationText';

        try {
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                channelName,
                channelDescription: channelDescription,
                importance: Importance.max,
                priority: Priority.high,
                category: AndroidNotificationCategory.alarm,
                ticker: 'Schedule Reminder',
                icon: '@mipmap/ic_launcher',
                styleInformation: BigTextStyleInformation(body),
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: entry.id,
          );
        } catch (e) {
          debugPrint('Error scheduling notification $notificationId: $e');
        }
      }
    }
  }

  /// Cancels all notifications associated with this schedule entry
  Future<void> cancelEntryReminders(ScheduleEntry entry) async {
    for (final dayOfWeek in entry.daysOfWeek) {
      for (final leadMinutes in entry.reminders) {
        final notificationId = _generateNotificationId(entry.id, dayOfWeek, leadMinutes);
        await _notificationsPlugin.cancel(notificationId);
      }
    }
  }

  /// Reschedules all active entries in the database
  Future<void> rescheduleAll(List<ScheduleEntry> entries) async {
    await _notificationsPlugin.cancelAll();
    for (final entry in entries) {
      if (entry.isActive) {
        await scheduleEntryReminders(entry);
      }
    }
  }

  /// Instant test notification
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Finds the next occurrence of [dayOfWeek] (1=Mon..7=Sun) at [hour]:[minute]
  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Adjust day of week
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If time has already passed today, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}
