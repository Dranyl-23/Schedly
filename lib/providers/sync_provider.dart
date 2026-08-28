import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/firestore_sync_service.dart';
import 'profile_provider.dart';
import 'schedule_provider.dart';

/// Single shared FirestoreSyncService instance.
/// Extracted here to avoid a circular import between
/// schedule_provider.dart and profile_provider.dart.
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  final service = FirestoreSyncService(scheduleRepo, profileRepo);
  ref.onDispose(() => service.dispose());
  return service;
});
