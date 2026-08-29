import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/schedule_entry.dart';

class ScheduleRepository {
  static const String boxName = 'schedules_box';
  Box<String>? _box;

  // BUG FIX (High #10): The _box field was declared `late` and accessed
  // directly in synchronous methods without any initialization guard.
  // If any method is called before init() completes, a LateInitializationError
  // is thrown and the app crashes. Using a nullable field + _safeBox getter
  // silently returns empty results instead of crashing.
  Box<String>? get _safeBox => (_box != null && _box!.isOpen) ? _box : null;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(boxName);
  }

  List<ScheduleEntry> getAllSchedules() {
    final box = _safeBox;
    if (box == null) return [];
    final List<ScheduleEntry> entries = [];
    for (final rawJson in box.values) {
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
    final box = _safeBox;
    if (box == null) return null;
    final rawJson = box.get(id);
    if (rawJson == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
      return ScheduleEntry.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSchedule(ScheduleEntry entry) async {
    final box = _safeBox;
    if (box == null) return;
    final jsonStr = jsonEncode(entry.toJson());
    await box.put(entry.id, jsonStr);
  }

  Future<void> saveBatch(List<ScheduleEntry> entries) async {
    final box = _safeBox;
    if (box == null) return;
    final Map<String, String> map = {};
    for (final entry in entries) {
      map[entry.id] = jsonEncode(entry.toJson());
    }
    await box.putAll(map);
  }

  Future<void> deleteSchedule(String id) async {
    await _safeBox?.delete(id);
  }

  Future<void> toggleActive(String id) async {
    final entry = getScheduleById(id);
    if (entry != null) {
      final updated = entry.copyWith(isActive: !entry.isActive);
      await saveSchedule(updated);
    }
  }

  Future<void> clearAll() async {
    await _safeBox?.clear();
  }
}
