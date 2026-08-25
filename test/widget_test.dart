import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_scanner/models/schedule_category.dart';
import 'package:schedule_scanner/models/schedule_entry.dart';
import 'package:schedule_scanner/core/utils/time_utils.dart';

void main() {
  group('ScheduleEntry Model Tests', () {
    test('ScheduleEntry serialization and deserialization', () {
      final entry = ScheduleEntry(
        id: 'test-123',
        title: 'Math 101 - Calculus',
        category: ScheduleCategory.classSchedule,
        daysOfWeek: [1, 3, 5],
        startTime: '08:30',
        endTime: '10:00',
        spansNextDay: false,
        location: 'Room 304',
        notes: 'Bring calculator',
        reminders: [15, 60],
        isActive: true,
      );

      final jsonMap = entry.toJson();
      final reconstructed = ScheduleEntry.fromJson(jsonMap);

      expect(reconstructed.id, equals(entry.id));
      expect(reconstructed.title, equals(entry.title));
      expect(reconstructed.category, equals(ScheduleCategory.classSchedule));
      expect(reconstructed.daysOfWeek, equals([1, 3, 5]));
      expect(reconstructed.startTime, equals('08:30'));
      expect(reconstructed.endTime, equals('10:00'));
      expect(reconstructed.spansNextDay, isFalse);
      expect(reconstructed.location, equals('Room 304'));
      expect(reconstructed.reminders, equals([15, 60]));
      expect(reconstructed.isActive, isTrue);
    });

    test('Overnight shift correctly flagged', () {
      final nightEntry = ScheduleEntry(
        title: 'Graveyard Shift',
        category: ScheduleCategory.workShift,
        daysOfWeek: [5, 6],
        startTime: '22:00',
        endTime: '06:00',
        spansNextDay: true,
      );

      expect(nightEntry.spansNextDay, isTrue);
      final duration = TimeUtils.calculateDuration(
        nightEntry.startTime,
        nightEntry.endTime,
        spansNextDay: nightEntry.spansNextDay,
      );
      expect(duration, equals('8h'));
    });
  });

  group('TimeUtils Tests', () {
    test('12-hour AM/PM formatting', () {
      expect(TimeUtils.formatTo12Hour('08:30'), equals('8:30 AM'));
      expect(TimeUtils.formatTo12Hour('12:00'), equals('12:00 PM'));
      expect(TimeUtils.formatTo12Hour('13:45'), equals('1:45 PM'));
      expect(TimeUtils.formatTo12Hour('22:00'), equals('10:00 PM'));
      expect(TimeUtils.formatTo12Hour('00:15'), equals('12:15 AM'));
    });

    test('Duration calculation', () {
      expect(TimeUtils.calculateDuration('08:00', '09:30'), equals('1h 30m'));
      expect(TimeUtils.calculateDuration('13:00', '17:00'), equals('4h'));
      expect(TimeUtils.calculateDuration('22:00', '06:00', spansNextDay: true), equals('8h'));
    });

    test('Weekday names conversion', () {
      expect(TimeUtils.getWeekdayShort(1), equals('Mon'));
      expect(TimeUtils.getWeekdayShort(7), equals('Sun'));
      expect(TimeUtils.getWeekdayFull(1), equals('Monday'));
      expect(TimeUtils.getWeekdayFull(5), equals('Friday'));
    });

    test('Reminder lead minutes formatting', () {
      expect(TimeUtils.formatLeadMinutes(0), equals('At event time'));
      expect(TimeUtils.formatLeadMinutes(15), equals('15 mins before'));
      expect(TimeUtils.formatLeadMinutes(60), equals('1 hour before'));
      expect(TimeUtils.formatLeadMinutes(120), equals('2 hours before'));
    });
  });
}
