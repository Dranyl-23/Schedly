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
      return (notifGranted ?? false) && (exactAlarmGranted ?? true);
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

  /// Helper to calculate the next occurrence of a given day of week and time
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

    // If today is the target weekday
    if (scheduledDate.weekday == dayOfWeek) {
      // If scheduled time is within the current minute or up to 60s in the past (e.g. testing right now)
      if (scheduledDate.isBefore(now)) {
        final diff = now.difference(scheduledDate);
        if (diff.inMinutes == 0 && diff.inSeconds <= 55) {
          // Trigger test alarm 2 seconds from now
          return now.add(const Duration(seconds: 2));
        } else {
          // Time on this weekday has already passed, schedule for next week (+7 days)
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }
      }
    } else {
      // Find the next matching weekday in the future
      while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          hour,
          minute,
        );
      }
    }

    return scheduledDate;
  }
}
