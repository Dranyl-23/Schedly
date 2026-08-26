import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/schedule_profile.dart';

class ProfileRepository {
  static const String boxName = 'profiles_box';
  Box<String>? _box;

  Box<String> get _safeBox {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(boxName)) return Hive.box<String>(boxName);
    throw StateError('ProfileRepository box has not been initialized');
  }

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);

    // If empty, initialize default profiles from design
    if (_box!.isEmpty) {
      final defaultProfiles = [
        ScheduleProfile(
          id: 'school-profile-1',
          name: 'School Schedule',
          type: 'school',
          colorHex: '#2563EB',
          isActive: true,
        ),
        ScheduleProfile(
          id: 'work-profile-2',
          name: 'Part-Time Job',
          type: 'work',
          colorHex: '#F97316',
          isActive: false,
        ),
        ScheduleProfile(
          id: 'duty-profile-3',
          name: 'Duty Roster',
          type: 'duty',
          colorHex: '#10B981',
          isActive: false,
        ),
      ];

      for (final p in defaultProfiles) {
        await _box!.put(p.id, jsonEncode(p.toJson()));
      }
    }
  }

  List<ScheduleProfile> getAllProfiles() {
    final List<ScheduleProfile> list = [];
    try {
      final box = _safeBox;
      for (final raw in box.values) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          list.add(ScheduleProfile.fromJson(map));
        } catch (_) {}
      }
    } catch (_) {}
    return list;
  }

  ScheduleProfile? getActiveProfile() {
    final all = getAllProfiles();
    try {
      return all.firstWhere((p) => p.isActive);
    } catch (_) {
      return all.isNotEmpty ? all.first : null;
    }
  }

  Future<void> setActiveProfile(String profileId) async {
    final all = getAllProfiles();
    final box = _safeBox;
    for (final p in all) {
      final updated = p.copyWith(isActive: p.id == profileId);
      await box.put(p.id, jsonEncode(updated.toJson()));
    }
  }

  Future<void> saveProfile(ScheduleProfile profile) async {
    await _safeBox.put(profile.id, jsonEncode(profile.toJson()));
  }

  Future<void> deleteProfile(String id) async {
    await _safeBox.delete(id);
  }
}
