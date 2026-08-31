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

  static const String channelVersion = 'v3';
  static const String baseChannelId = 'reminda_alarm_$channelVersion';
  static const String channelName = 'Reminda Alarms';
  static const String channelDescription =
      'High-priority Reminda alarms and reminders for classes, shifts, and duties';

  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 1000, 500, 1000]);

  // FLAG_INSISTENT (4) causes Android to loop the alarm audio continuously until dismissed
  static final Int32List _insistentFlags = Int32List.fromList([4]);

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
        final channelId = 'reminda_alarm_${channelVersion}_${tone.id}';
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
          vibrationPattern: _vibrationPattern,
          showBadge: true,
          enableLights: true,
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

      final bool alarmOk = exactAlarmGranted ?? false;
      if (!alarmOk) {
        debugPrint(
          'NotificationService: Exact alarm permission NOT granted. '
          'Alarms will use exactAllowWhileIdle or inexact fallback. '
          'Ask user to grant "Alarms & Reminders" in settings for instant precision.',
        );
      }
      return (notifGranted ?? false);
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

  Future<bool> isExactAlarmPermissionGranted() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return (await androidImplementation?.requestExactAlarmsPermission()) ?? false;
  }

  String _getActiveToneId() {
    String toneId = 'crystal_chime';
    try {
      if (Hive.isBoxOpen('app_settings_box')) {
        toneId = Hive.box('app_settings_box').get('default_alarm_tone_id', defaultValue: 'crystal_chime') as String;
      } else if (Hive.isBoxOpen('user_setup_box')) {
        toneId = Hive.box('user_setup_box').get('selectedToneId', defaultValue: 'crystal_chime') as String;
      }
    } catch (_) {}
    return toneId;
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

  /// Helper to reliably schedule alarms across Android 12, 13, 14+ with multi-tier fallback
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required DateTimeComponents matchDateTimeComponents,
    required String payload,
  }) async {
    // Tier 1: Try exact alarmClock mode (wakes screen & rings loudly through Doze mode)
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
      debugPrint('NotificationService: Scheduled alarmClock #$id for $scheduledDate');
      return;
    } catch (e) {
      debugPrint('NotificationService: alarmClock mode failed (#$id): $e. Trying exactAllowWhileIdle...');
    }

    // Tier 2: Try exactAllowWhileIdle mode
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
      debugPrint('NotificationService: Scheduled exactAllowWhileIdle #$id for $scheduledDate');
      return;
    } catch (e) {
      debugPrint('NotificationService: exactAllowWhileIdle failed (#$id): $e. Trying inexact fallback...');
    }

    // Tier 3: Inexact fallback (guarantees status bar notification execution on all devices)
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
      debugPrint('NotificationService: Scheduled inexact fallback #$id for $scheduledDate');
    } catch (e) {
      debugPrint('NotificationService: All scheduling attempts failed for #$id: $e');
    }
  }

  /// Triggers an immediate test notification with ringtone, vibration, and banner
  Future<void> showTestNotification({String? toneId}) async {
    final activeToneId = toneId ?? _getActiveToneId();
    final channelId = 'reminda_alarm_${channelVersion}_$activeToneId';
    final soundResource = activeToneId == 'system_default'
        ? null
        : RawResourceAndroidNotificationSound(activeToneId);

    const title = 'Reminda Alarm Test';
    final body = 'Alarm sound ($activeToneId), vibration, and status bar notifications are active!';

    await _notificationsPlugin.show(
      999999,
      title,
      body,
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
          ticker: 'Reminda Alarm Test',
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          channelShowBadge: true,
          autoCancel: true,
          enableLights: true,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
          additionalFlags: _insistentFlags,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: activeToneId == 'system_default' ? null : '$activeToneId.wav',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'test_notification',
    );
  }

  /// Schedules all reminders for a schedule entry across all selected weekdays
  Future<void> scheduleEntryReminders(ScheduleEntry entry) async {
    if (!entry.isActive) return;

    final startParts = entry.startTime.split(':');
    if (startParts.length != 2) return;

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);

    final toneId = _getActiveToneId();
    final channelId = 'reminda_alarm_${channelVersion}_$toneId';
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

        await _safeZonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          details: NotificationDetails(
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
              vibrationPattern: _vibrationPattern,
              additionalFlags: _insistentFlags,
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
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: entry.id,
        );
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
    debugPrint('NotificationService: Successfully rescheduled ${entries.where((e) => e.isActive).length} active schedules.');
  }

  /// Cancel all scheduled alarms and notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Helper to calculate the next occurrence of a given day of week and time.
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
