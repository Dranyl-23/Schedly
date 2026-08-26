import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_category.dart';
import '../models/schedule_entry.dart';
import 'schedule_provider.dart';

/// Currently selected date in the calendar strip (defaults to today)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Optional category filter chip
final selectedCategoryFilterProvider = StateProvider<ScheduleCategory?>((ref) {
  return null; // null means "All categories"
});

/// Active schedule entries for the selected day of the week
final schedulesForSelectedDateProvider = Provider<List<ScheduleEntry>>((ref) {
  final allSchedules = ref.watch(scheduleListProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final categoryFilter = ref.watch(selectedCategoryFilterProvider);

  final weekday = selectedDate.weekday; // 1 = Mon, 7 = Sun

  return allSchedules.where((entry) {
    final matchesDay = entry.daysOfWeek.contains(weekday);
    final matchesCategory = categoryFilter == null || entry.category == categoryFilter;
    return matchesDay && matchesCategory;
  }).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});

/// Schedules specifically for today's weekday
final schedulesForTodayProvider = Provider<List<ScheduleEntry>>((ref) {
  final allSchedules = ref.watch(scheduleListProvider);
  final weekday = DateTime.now().weekday;

  return allSchedules.where((entry) => entry.daysOfWeek.contains(weekday)).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});

/// Counts how many schedule entries exist for each weekday (1..7)
final weeklyScheduleCountsProvider = Provider<Map<int, int>>((ref) {
  final allSchedules = ref.watch(scheduleListProvider);
  final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

  for (final entry in allSchedules) {
    if (!entry.isActive) continue;
    for (final day in entry.daysOfWeek) {
      counts[day] = (counts[day] ?? 0) + 1;
    }
  }

  return counts;
});

/// Next upcoming schedule item for today
final upcomingTodayScheduleProvider = Provider<ScheduleEntry?>((ref) {
  final allSchedules = ref.watch(scheduleListProvider);
  final now = DateTime.now();
  final currentWeekday = now.weekday;
  final currentMinutes = now.hour * 60 + now.minute;

  final todayEntries = allSchedules.where((e) => e.isActive && e.daysOfWeek.contains(currentWeekday)).toList();
  todayEntries.sort((a, b) => a.startTime.compareTo(b.startTime));

  for (final entry in todayEntries) {
    final startParts = entry.startTime.split(':');
    if (startParts.length == 2) {
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      if (startMin >= currentMinutes) {
        return entry;
      }
    }
  }

  // If no more entries today, return first entry if active
  return null;
});
