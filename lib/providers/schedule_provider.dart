import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/firestore_sync_service.dart';
import '../core/database/schedule_repository.dart';
import '../core/notifications/notification_service.dart';
import '../models/schedule_entry.dart';
import 'sync_provider.dart';

export 'ai_settings_provider.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// firestoreSyncServiceProvider is defined in sync_provider.dart
// and imported above — used by ScheduleNotifier below.

class ScheduleNotifier extends StateNotifier<List<ScheduleEntry>> {
  final ScheduleRepository _repository;
  final NotificationService _notificationService;
  final FirestoreSyncService _syncService;

  ScheduleNotifier(
    this._repository,
    this._notificationService,
    this._syncService,
  ) : super([]) {
    _loadSchedules();
    _syncService.startSync(onDataChanged: () => _loadSchedules());
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
    await _syncService.syncScheduleToCloud(entry);
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
    await _syncService.syncScheduleToCloud(updated);
  }

  Future<void> deleteSchedule(ScheduleEntry entry) async {
    await _notificationService.cancelEntryReminders(entry);
    await _repository.deleteSchedule(entry.id);
    _loadSchedules();
    await _syncService.deleteScheduleFromCloud(entry.id);
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
    await _syncService.syncScheduleToCloud(updated);
  }

  Future<void> importBatch(List<ScheduleEntry> entries) => addBatch(entries);

  Future<void> addBatch(List<ScheduleEntry> entries) async {
    await _repository.saveBatch(entries);
    for (final entry in entries) {
      if (entry.isActive) {
        await _notificationService.scheduleEntryReminders(entry);
      }
    }
    _loadSchedules();
    await _syncService.syncBatchSchedulesToCloud(entries);
  }

  Future<void> clearAll() async {
    await _notificationService.rescheduleAll([]);
    final current = _repository.getAllSchedules();
    for (final entry in current) {
      _syncService.deleteScheduleFromCloud(entry.id);
    }
    await _repository.clearAll();
    state = [];
  }

  Future<void> deleteSchedulesForProfile(String profileId) async {
    final all = _repository.getAllSchedules();
    final toDelete = all.where((e) => e.profileId == profileId || (e.profileId == null)).toList();
    for (final entry in toDelete) {
      await _notificationService.cancelEntryReminders(entry);
      await _repository.deleteSchedule(entry.id);
      await _syncService.deleteScheduleFromCloud(entry.id);
    }
    _loadSchedules();
  }

  Future<void> refreshFromCloud() async {
    await _syncService.pullAndSyncAll(onDataChanged: () => _loadSchedules());
    _loadSchedules();
  }

  void clearLocalMemory() {
    state = [];
  }

  void refreshFromLocal() {
    _loadSchedules();
  }
}

final scheduleListProvider =
    StateNotifierProvider<ScheduleNotifier, List<ScheduleEntry>>((ref) {
  final repo = ref.watch(scheduleRepositoryProvider);
  final notif = ref.watch(notificationServiceProvider);
  final sync = ref.watch(firestoreSyncServiceProvider);
  return ScheduleNotifier(repo, notif, sync);
});
