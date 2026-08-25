import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/schedule_entry.dart';

class ScheduleRepository {
  static const String boxName = 'schedules_box';
  late Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(boxName);
  }

  List<ScheduleEntry> getAllSchedules() {
    final List<ScheduleEntry> entries = [];
    for (final rawJson in _box.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
        entries.add(ScheduleEntry.fromJson(map));
      } catch (e) {
        // Skip corrupted entries
      }
    }
    // Sort by startTime
    entries.sort((a, b) => a.startTime.compareTo(b.startTime));
    return entries;
  }

  ScheduleEntry? getScheduleById(String id) {
    final rawJson = _box.get(id);
    if (rawJson == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
      return ScheduleEntry.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSchedule(ScheduleEntry entry) async {
    final jsonStr = jsonEncode(entry.toJson());
    await _box.put(entry.id, jsonStr);
  }

  Future<void> saveBatch(List<ScheduleEntry> entries) async {
    final Map<String, String> map = {};
    for (final entry in entries) {
      map[entry.id] = jsonEncode(entry.toJson());
    }
    await _box.putAll(map);
  }

  Future<void> deleteSchedule(String id) async {
    await _box.delete(id);
  }

  Future<void> toggleActive(String id) async {
    final entry = getScheduleById(id);
    if (entry != null) {
      final updated = entry.copyWith(isActive: !entry.isActive);
      await saveSchedule(updated);
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
