import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils/time_utils.dart';
import '../models/app_notification.dart';
import 'schedule_provider.dart';

class NotificationCenterNotifier extends StateNotifier<List<AppNotification>> {
  static const String boxName = 'app_notifications_box';
  Box? _box;

  NotificationCenterNotifier(Ref ref) : super([]) {
    _init(ref);
  }

  Future<void> _init(Ref ref) async {
    _box = await Hive.openBox(boxName);
    _loadFromCache();

    // Listen to schedules to automatically generate smart briefing & upcoming reminders
    ref.listen(scheduleListProvider, (previous, next) {
      _generateDynamicNotifications(next);
    });

    final currentSchedules = ref.read(scheduleListProvider);
    _generateDynamicNotifications(currentSchedules);
  }

  void _loadFromCache() {
    if (_box == null) return;
    final List<AppNotification> list = [];
    for (var i = 0; i < _box!.length; i++) {
      try {
        final raw = _box!.getAt(i);
        if (raw is Map) {
          list.add(AppNotification.fromJson(Map<String, dynamic>.from(raw)));
        }
      } catch (_) {}
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = list;
  }

  Future<void> _saveToCache() async {
    if (_box == null) return;
    await _box!.clear();
    for (final item in state) {
      await _box!.add(item.toJson());
    }
  }

  void _generateDynamicNotifications(dynamic schedules) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;

    final todayEntries = (schedules as List)
        .where((e) => e.isActive && e.daysOfWeek.contains(currentWeekday))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final currentList = List<AppNotification>.from(state);

    // 1. Generate Daily Briefing if not exists today
    final briefingId = 'briefing_${now.year}_${now.month}_${now.day}';
    final hasBriefing = currentList.any((n) => n.id == briefingId);

    if (!hasBriefing && todayEntries.isNotEmpty) {
      final firstClass = todayEntries.first;
      final count = todayEntries.length;
      final briefing = AppNotification(
        id: briefingId,
        title: '☀️ Today\'s Schedule Briefing',
        body: 'You have $count ${count > 1 ? 'classes & shifts' : 'event'} today starting with "${firstClass.title}" at ${TimeUtils.formatTo12Hour(firstClass.startTime)}.',
        type: NotificationType.briefing,
        timestamp: DateTime(now.year, now.month, now.day, 7, 0),
        isRead: false,
      );
      currentList.insert(0, briefing);
    }

    // 2. Generate Reminder alerts for today's active classes
    for (final entry in todayEntries) {
      final reminderId = 'reminder_${now.year}_${now.month}_${now.day}_${entry.id}';
      final hasReminder = currentList.any((n) => n.id == reminderId);

      if (!hasReminder) {
        final roomText = entry.location != null && entry.location!.isNotEmpty ? ' at ${entry.location}' : '';
        final reminder = AppNotification(
          id: reminderId,
          title: '⏰ Upcoming: ${entry.title}',
          body: 'Scheduled from ${TimeUtils.formatTo12Hour(entry.startTime)} to ${TimeUtils.formatTo12Hour(entry.endTime)}$roomText.',
          type: NotificationType.reminder,
          timestamp: DateTime(now.year, now.month, now.day, 8, 0),
          isRead: false,
          relatedScheduleId: entry.id,
        );
        currentList.insert(0, reminder);
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
