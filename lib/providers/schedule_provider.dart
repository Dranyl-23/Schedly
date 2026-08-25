import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/schedule_repository.dart';
import '../core/notifications/notification_service.dart';
import '../models/schedule_entry.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final geminiApiKeyProvider = StateProvider<String>((ref) {
  return ''; // Can be set in app settings by user
});

class ScheduleNotifier extends StateNotifier<List<ScheduleEntry>> {
  final ScheduleRepository _repository;
  final NotificationService _notificationService;

  ScheduleNotifier(this._repository, this._notificationService) : super([]) {
    _loadSchedules();
  }

  void _loadSchedules() {
    final schedules = _repository.getAllSchedules();
    state = schedules;
  }

  Future<void> addSchedule(ScheduleEntry entry) async {
    await _repository.saveSchedule(entry);
    if (entry.isActive) {
      await _notificationService.scheduleEntryReminders(entry);
    }
    _loadSchedules();
  }

  Future<void> updateSchedule(ScheduleEntry updated) async {
    final existing = _repository.getScheduleById(updated.id);
    if (existing != null) {
      await _notificationService.cancelEntryReminders(existing);
    }
    await _repository.saveSchedule(updated);
    if (updated.isActive) {
      await _notificationService.scheduleEntryReminders(updated);
    }
    _loadSchedules();
  }

  Future<void> deleteSchedule(ScheduleEntry entry) async {
    await _notificationService.cancelEntryReminders(entry);
    await _repository.deleteSchedule(entry.id);
    _loadSchedules();
  }

  Future<void> toggleActive(String id) async {
    final entry = _repository.getScheduleById(id);
    if (entry == null) return;

    final updated = entry.copyWith(isActive: !entry.isActive);
    if (updated.isActive) {
      await _notificationService.scheduleEntryReminders(updated);
    } else {
      await _notificationService.cancelEntryReminders(entry);
    }
    await _repository.saveSchedule(updated);
    _loadSchedules();
  }

  Future<void> importBatch(List<ScheduleEntry> entries) async {
    await _repository.saveBatch(entries);
    for (final entry in entries) {
      if (entry.isActive) {
        await _notificationService.scheduleEntryReminders(entry);
      }
    }
    _loadSchedules();
  }

  Future<void> clearAll() async {
    await _notificationService.rescheduleAll([]);
    await _repository.clearAll();
    state = [];
  }
}

final scheduleListProvider =
    StateNotifierProvider<ScheduleNotifier, List<ScheduleEntry>>((ref) {
  final repo = ref.watch(scheduleRepositoryProvider);
  final notif = ref.watch(notificationServiceProvider);
  return ScheduleNotifier(repo, notif);
});
