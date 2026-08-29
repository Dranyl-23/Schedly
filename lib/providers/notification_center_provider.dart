import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils/time_utils.dart';
import '../models/app_notification.dart';
import '../models/schedule_entry.dart';
import 'schedule_provider.dart';

class NotificationCenterNotifier extends StateNotifier<List<AppNotification>> {
  static const String boxName = 'app_notifications_box';
  Box? _box;

  // BUG FIX (Critical #3): ref.listen() MUST be called synchronously in the
  // constructor. Calling it inside an async method (after an `await`) violates
  // Riverpod's rules and throws a StateError at runtime, silently breaking the
  // entire notification center. The Hive box open is the only async work and
  // stays in _init(); the listener registration moves here to the constructor.
  NotificationCenterNotifier(Ref ref) : super([]) {
    // ✅ Register the schedule listener synchronously before any async work
    ref.listen(scheduleListProvider, (previous, next) {
      _generateDynamicNotifications(next);
    });

    // Kick off async initialization (open Hive box, load cache, build initial state)
    _init(ref);
  }

  Future<void> _init(Ref ref) async {
    _box = await Hive.openBox(boxName);
    _loadFromCache();

    // Generate dynamic notifications from the current schedule state
    final currentSchedules = ref.read(scheduleListProvider);
    _generateDynamicNotifications(currentSchedules);
  }

  static const String _cacheKey = 'cached_notifications_list';

  void _loadFromCache() {
    if (_box == null) return;
    final List<AppNotification> list = [];
    final rawList = _box!.get(_cacheKey);
    if (rawList is List) {
      for (final raw in rawList) {
        try {
          if (raw is Map) {
            list.add(AppNotification.fromJson(Map<String, dynamic>.from(raw)));
          }
        } catch (_) {}
      }
    } else {
      // Backward compatibility for legacy item-by-item format
      for (var i = 0; i < _box!.length; i++) {
        try {
          final raw = _box!.getAt(i);
          if (raw is Map) {
            list.add(AppNotification.fromJson(Map<String, dynamic>.from(raw)));
          }
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = list;
  }

  Future<void> _saveToCache() async {
    if (_box == null) return;
    final jsonList = state.map((item) => item.toJson()).toList();
    await _box!.put(_cacheKey, jsonList);
  }

  void _generateDynamicNotifications(List<ScheduleEntry> schedules) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final yesterdayWeekday = currentWeekday == 1 ? 7 : currentWeekday - 1;

    int parseMinutes(String t) {
      final p = t.split(':');
      return p.length >= 2 ? (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0) : 0;
    }

    final todayEntries = schedules
        .where((e) {
          if (!e.isActive) return false;
          if (e.daysOfWeek.contains(currentWeekday)) return true;
          if (e.spansNextDay && e.daysOfWeek.contains(yesterdayWeekday)) {
            final endMinutes = parseMinutes(e.endTime);
            final currentMinutes = now.hour * 60 + now.minute;
            return currentMinutes < endMinutes;
          }
          return false;
        })
        .toList()
      ..sort((a, b) => parseMinutes(a.startTime).compareTo(parseMinutes(b.startTime)));

    final currentList = List<AppNotification>.from(state);

    // 1. Generate Daily Briefing if not exists today
    final briefingId = 'briefing_${now.year}_${now.month}_${now.day}';
    final briefingIndex = currentList.indexWhere((n) => n.id == briefingId);

    if (todayEntries.isNotEmpty) {
      final firstClass = todayEntries.first;
      final count = todayEntries.length;
      final briefingTime = DateTime(now.year, now.month, now.day, 7, 0);
      final briefingTimestamp = now.isBefore(briefingTime) ? now : briefingTime;

      final briefing = AppNotification(
        id: briefingId,
        title: 'Today\'s Schedule Briefing',
        body: 'You have $count ${count > 1 ? 'classes & shifts' : 'event'} today starting with "${firstClass.title}" at ${TimeUtils.formatTo12Hour(firstClass.startTime)}.',
        type: NotificationType.briefing,
        timestamp: briefingIndex != -1 ? currentList[briefingIndex].timestamp : briefingTimestamp,
        isRead: briefingIndex != -1 ? currentList[briefingIndex].isRead : false,
      );

      if (briefingIndex != -1) {
        currentList[briefingIndex] = briefing;
      } else {
        currentList.insert(0, briefing);
      }
    }

    // 2. Generate / Update Real-Time Reminder alerts for today's active classes
    for (final entry in todayEntries) {
      final reminderId = 'reminder_${now.year}_${now.month}_${now.day}_${entry.id}';
      final existingIndex = currentList.indexWhere((n) => n.id == reminderId);

      final roomText = entry.location != null && entry.location!.trim().isNotEmpty
          ? ' at ${entry.location!.trim()}'
          : '';

      final startParts = entry.startTime.split(':');
      final endParts = entry.endTime.split(':');
      final startHour = int.tryParse(startParts[0]) ?? 0;
      final startMin = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;
      final endHour = int.tryParse(endParts[0]) ?? 0;
      final endMin = int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0;

      final startDateTime = DateTime(now.year, now.month, now.day, startHour, startMin);
      final DateTime endDateTime;
      if (entry.spansNextDay || (endHour * 60 + endMin) < (startHour * 60 + startMin)) {
        endDateTime = DateTime(now.year, now.month, now.day, endHour, endMin).add(const Duration(days: 1));
      } else {
        endDateTime = DateTime(now.year, now.month, now.day, endHour, endMin);
      }

      final String notifTitle;
      final String notifBody;
      final DateTime notifTimestamp;

      if (now.isAfter(endDateTime)) {
        // Event is already finished
        notifTitle = 'Completed: ${entry.title}';
        notifBody = 'Finished at ${TimeUtils.formatTo12Hour(entry.endTime)}$roomText.';
        notifTimestamp = endDateTime;
      } else if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
        // Event is currently happening
        notifTitle = 'Ongoing: ${entry.title}';
        notifBody = 'Started at ${TimeUtils.formatTo12Hour(entry.startTime)} • Ends at ${TimeUtils.formatTo12Hour(entry.endTime)}$roomText.';
        notifTimestamp = startDateTime;
      } else {
        // Event is upcoming later today
        final leadMins = entry.reminders.isNotEmpty ? entry.reminders.first : 15;
        final leadTime = startDateTime.subtract(Duration(minutes: leadMins));
        final diffMins = startDateTime.difference(now).inMinutes;
        final timeText = diffMins > 60
            ? 'in ${(diffMins / 60).floor()}h ${diffMins % 60}m'
            : 'in $diffMins mins';

        notifTitle = 'Upcoming: ${entry.title}';
        notifBody = 'Starts at ${TimeUtils.formatTo12Hour(entry.startTime)} ($timeText)$roomText.';
        notifTimestamp = now.isAfter(leadTime) ? leadTime : now;
      }

      final reminder = AppNotification(
        id: reminderId,
        title: notifTitle,
        body: notifBody,
        type: NotificationType.reminder,
        timestamp: notifTimestamp,
        isRead: existingIndex != -1 ? currentList[existingIndex].isRead : false,
        relatedScheduleId: entry.id,
      );

      if (existingIndex != -1) {
        currentList[existingIndex] = reminder;
      } else {
        currentList.add(reminder);
      }
    }

    currentList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = currentList;
    _saveToCache();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? relatedScheduleId,
  }) async {
    final newNotif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      relatedScheduleId: relatedScheduleId,
    );

    state = [newNotif, ...state];
    await _saveToCache();
  }

  Future<void> markAsRead(String id) async {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    await _saveToCache();
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _saveToCache();
  }

  Future<void> deleteNotification(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _saveToCache();
  }

  Future<void> clearAll() async {
    state = [];
    await _saveToCache();
  }
}

final notificationCenterProvider =
    StateNotifierProvider<NotificationCenterNotifier, List<AppNotification>>((ref) {
  return NotificationCenterNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationCenterProvider);
  return notifs.where((n) => !n.isRead).length;
});
