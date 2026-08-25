import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/profile_repository.dart';
import '../models/schedule_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileNotifier extends StateNotifier<List<ScheduleProfile>> {
  final ProfileRepository _repo;

  ProfileNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAllProfiles();
  }

  Future<void> setActive(String id) async {
    await _repo.setActiveProfile(id);
    _load();
  }

  Future<void> addProfile(ScheduleProfile profile) async {
    await _repo.saveProfile(profile);
    _load();
  }

  Future<void> deleteProfile(String id) async {
    await _repo.deleteProfile(id);
    _load();
  }
}

final profileListProvider =
    StateNotifierProvider<ProfileNotifier, List<ScheduleProfile>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repo);
});

final activeProfileProvider = Provider<ScheduleProfile?>((ref) {
  final profiles = ref.watch(profileListProvider);
  try {
    return profiles.firstWhere((p) => p.isActive);
  } catch (_) {
    return profiles.isNotEmpty ? profiles.first : null;
  }
});
