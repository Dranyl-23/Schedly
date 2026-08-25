import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeUtils {
  static const List<String> weekdayShortNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  static const List<String> weekdayFullNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  /// Returns 3-letter abbreviation (1 = Mon, 7 = Sun)
  static String getWeekdayShort(int day) {
    if (day >= 1 && day <= 7) {
      return weekdayShortNames[day - 1];
    }
    return '';
  }

  /// Returns full weekday name (1 = Monday, 7 = Sunday)
  static String getWeekdayFull(int day) {
    if (day >= 1 && day <= 7) {
      return weekdayFullNames[day - 1];
    }
    return '';
  }

  /// Formats HH:mm string (24h) to 12h display e.g. "8:30 AM" or "10:00 PM"
  static String formatTo12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2026, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time24;
    }
  }

  /// Converts TimeOfDay to "HH:mm" string
  static String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Converts "HH:mm" string to TimeOfDay
  static TimeOfDay stringToTimeOfDay(String time24) {
    try {
      final parts = time24.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  /// Calculates duration in hours and minutes (e.g. "1h 30m" or "8h")
  static String calculateDuration(String startTime, String endTime, {bool spansNextDay = false}) {
    try {
      final start = stringToTimeOfDay(startTime);
      final end = stringToTimeOfDay(endTime);

      int startMinutes = start.hour * 60 + start.minute;
      int endMinutes = end.hour * 60 + end.minute;

      if (spansNextDay || endMinutes < startMinutes) {
        endMinutes += 24 * 60;
      }

      int diffMinutes = endMinutes - startMinutes;
      if (diffMinutes <= 0) return '';

      int hours = diffMinutes ~/ 60;
      int minutes = diffMinutes % 60;

      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}m';
      }
    } catch (_) {
      return '';
    }
  }

  /// Checks if time string spans overnight (end is before start)
  static bool checkSpansOvernight(String startTime, String endTime) {
    try {
      final start = stringToTimeOfDay(startTime);
      final end = stringToTimeOfDay(endTime);
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      return endMinutes < startMinutes;
    } catch (_) {
      return false;
    }
  }

  /// Formats reminder lead time minutes into friendly label
  static String formatLeadMinutes(int minutes) {
    if (minutes == 0) return 'At event time';
    if (minutes < 60) return '$minutes mins before';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return hours == 1 ? '1 hour before' : '$hours hours before';
    }
    return '$hours hr $remainingMins min before';
  }
}
