import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/firestore_sync_service.dart';
import '../core/database/profile_repository.dart';
import '../core/database/schedule_repository.dart';
import '../models/schedule_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileNotifier extends StateNotifier<List<ScheduleProfile>> {
  final ProfileRepository _repo;
  final FirestoreSyncService _syncService;

  ProfileNotifier(this._repo, this._syncService) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAllProfiles();
  }

  Future<void> setActive(String id) async {
    await _repo.setActiveProfile(id);
    _load();
    for (final p in state) {
      _syncService.syncProfileToCloud(p);
    }
  }

  Future<void> addProfile(ScheduleProfile profile) async {
    await _repo.saveProfile(profile);
    _load();
    _syncService.syncProfileToCloud(profile);
  }

  Future<void> deleteProfile(String id) async {
    final wasActive = state.any((p) => p.id == id && p.isActive);
    await _repo.deleteProfile(id);
    _load();
    _syncService.deleteProfileFromCloud(id);

    if (wasActive && state.isNotEmpty) {
      await setActive(state.first.id);
    }
  }

  void refreshFromLocal() {
    _load();
  }
}

final profileListProvider =
    StateNotifierProvider<ProfileNotifier, List<ScheduleProfile>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  final scheduleRepo = ScheduleRepository();
  final syncService = FirestoreSyncService(scheduleRepo, repo);
  return ProfileNotifier(repo, syncService);
});

final activeProfileProvider = Provider<ScheduleProfile?>((ref) {
  final profiles = ref.watch(profileListProvider);
  try {
    return profiles.firstWhere((p) => p.isActive);
  } catch (_) {
    return profiles.isNotEmpty ? profiles.first : null;
  }
});
