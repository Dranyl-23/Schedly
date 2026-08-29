import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/alarm_tone.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';
import '../utils/time_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String baseChannelId = 'reminda_alarm_channel';
  static const String channelName = 'Reminda Alarms';
  static const String channelDescription =
      'High-priority Reminda alarms and reminders for classes, shifts, and duties';

  Future<void> initialize() async {
    // 1. Initialize timezone database and detect device location
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Local timezone initialized to $timeZoneName');
    } catch (e) {
      debugPrint('NotificationService: Timezone detection fallback: $e');
      try {
        final offset = DateTime.now().timeZoneOffset;
        final location = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == offset.inMilliseconds,
          orElse: () => tz.getLocation('Asia/Manila'),
        );
        tz.setLocalLocation(location);
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      }
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

    // 5. Create Android Notification Channels for all custom alarm ringtones
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      for (final tone in AlarmTone.presets) {
        final channelId = 'reminda_alarm_${tone.id}';
        final soundResource = tone.id == 'system_default'
            ? null
            : RawResourceAndroidNotificationSound(tone.id);

        final channel = AndroidNotificationChannel(
          channelId,
          'Reminda Alarms (${tone.name})',
          description: 'High-priority alarms with ${tone.name} ringtone',
          importance: Importance.max,
          playSound: true,
          sound: soundResource,
          enableVibration: true,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        await androidImplementation.createNotificationChannel(channel);
      }
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final notifGranted =
          await androidImplementation?.requestNotificationsPermission();
      final exactAlarmGranted =
          await androidImplementation?.requestExactAlarmsPermission();

      // Do NOT fall back to true — if the platform returns null the permission
      // is NOT confirmed, so we must treat it as denied to avoid a silent
      // SecurityException when AndroidScheduleMode.alarmClock is used.
      final bool alarmOk = exactAlarmGranted ?? false;
      if (!alarmOk) {
        debugPrint(
          'NotificationService: Exact alarm permission NOT granted. '
          'Scheduled alarms may not fire. '
          'Ask the user to grant "Alarms & Reminders" in device settings.',
        );
      }
      return (notifGranted ?? false) && alarmOk;
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
  int _generateNotificationId(String entryId, int dayOfWeek, int leadMinutes) {
    final key = '$entryId-$dayOfWeek-$leadMinutes';
    // FNV-1a 32-bit hash
    var hash = 0x811c9dc5;
    for (final codeUnit in key.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  /// Schedules all reminders for a schedule entry across all selected weekdays
  Future<void> scheduleEntryReminders(ScheduleEntry entry) async {
    if (!entry.isActive) return;

    final startParts = entry.startTime.split(':');
    if (startParts.length != 2) return;

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);

    // Retrieve active alarm tone ID from settings or user setup
    String toneId = 'crystal_chime';
    try {
      if (Hive.isBoxOpen('app_settings_box')) {
        toneId = Hive.box('app_settings_box').get('default_alarm_tone_id', defaultValue: 'crystal_chime') as String;
      } else if (Hive.isBoxOpen('user_setup_box')) {
        toneId = Hive.box('user_setup_box').get('selectedToneId', defaultValue: 'crystal_chime') as String;
      }
    } catch (_) {}

    final channelId = 'reminda_alarm_$toneId';
    final soundResource = toneId == 'system_default'
        ? null
        : RawResourceAndroidNotificationSound(toneId);

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
          alarmDay = alarmDay == 1 ? 7 : alarmDay - 1;
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

        final String title = '${entry.category.shortLabel}: ${entry.title}';
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
                'Reminda Alarms',
                channelDescription: channelDescription,
                importance: Importance.max,
                priority: Priority.max,
                category: AndroidNotificationCategory.alarm,
                audioAttributesUsage: AudioAttributesUsage.alarm,
                sound: soundResource,
                ticker: 'Schedule Reminder',
                icon: '@mipmap/ic_launcher',
                styleInformation: BigTextStyleInformation(body),
                fullScreenIntent: true,
                visibility: NotificationVisibility.public,
                channelShowBadge: true,
                autoCancel: true,
                enableLights: true,
                enableVibration: true,
                playSound: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                sound: toneId == 'system_default' ? null : '$toneId.wav',
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
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

  /// Cancel all scheduled alarms and notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Helper to calculate the next occurrence of a given day of week and time.
  ///
  /// Uses a unified forward-scan loop so "today already passed" and
  /// "other weekday" are handled identically, avoiding the old fragile
  /// 55-second special-case window that silently scheduled alarms 7 days
  /// ahead when called even 56 seconds after the target time.
  ///
  /// A 30-second grace window lets alarms saved moments before their
  /// scheduled time still fire in the immediate future rather than next week.
  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Build the candidate for today at the requested time.
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Walk forward one day at a time until we land on the correct weekday
    // AND the time is still in the future (with a 30-second grace window so
    // a schedule saved just before its trigger time doesn't skip to next week).
    final tz.TZDateTime cutoff = now.subtract(const Duration(seconds: 30));
    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(cutoff)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day + 1,
        hour,
        minute,
      );
    }

    return scheduledDate;
  }
}
