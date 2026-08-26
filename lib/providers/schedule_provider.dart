import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/config/app_config.dart';
import '../core/database/firestore_sync_service.dart';
import '../core/database/schedule_repository.dart';
import '../core/notifications/notification_service.dart';
import '../models/schedule_entry.dart';
import 'profile_provider.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  final service = FirestoreSyncService(scheduleRepo, profileRepo);
  ref.onDispose(() => service.dispose());
  return service;
});

class GeminiKeyNotifier extends StateNotifier<String> {
  static const String _keyName = 'gemini_api_key';
  Box? _box;

  GeminiKeyNotifier() : super(AppConfig.defaultGeminiApiKey) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox('app_settings_box');
    final saved = _box?.get(_keyName, defaultValue: AppConfig.defaultGeminiApiKey) as String;
    state = saved.isNotEmpty ? saved : AppConfig.defaultGeminiApiKey;
  }

  Future<void> setKey(String key) async {
    _box ??= await Hive.openBox('app_settings_box');
    final finalKey = key.trim().isNotEmpty ? key.trim() : AppConfig.defaultGeminiApiKey;
    await _box?.put(_keyName, finalKey);
    state = finalKey;
  }
}

final geminiApiKeyProvider =
    StateNotifierProvider<GeminiKeyNotifier, String>((ref) {
  return GeminiKeyNotifier();
});

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
    _syncService.syncScheduleToCloud(entry);
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
    _syncService.syncScheduleToCloud(updated);
  }

  Future<void> deleteSchedule(ScheduleEntry entry) async {
    await _notificationService.cancelEntryReminders(entry);
    await _repository.deleteSchedule(entry.id);
    _loadSchedules();
    _syncService.deleteScheduleFromCloud(entry.id);
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
    _syncService.syncScheduleToCloud(updated);
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
    _syncService.syncBatchSchedulesToCloud(entries);
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

  Future<void> refreshFromCloud() async {
    await _syncService.pullAndSyncAll();
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
