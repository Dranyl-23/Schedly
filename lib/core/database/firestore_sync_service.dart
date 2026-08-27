import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/schedule_entry.dart';
import '../../models/schedule_profile.dart';
import 'profile_repository.dart';
import 'schedule_repository.dart';

class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScheduleRepository _scheduleRepo;
  final ProfileRepository _profileRepo;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _schedulesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _profilesSubscription;

  FirestoreSyncService(this._scheduleRepo, this._profileRepo);

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _userSchedulesRef {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('schedules');
  }

  CollectionReference<Map<String, dynamic>>? get _userProfilesRef {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('profiles');
  }

  /// Initialize real-time synchronization between Hive and Cloud Firestore
  void startSync({
    VoidCallback? onDataChanged,
  }) {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        debugPrint('FirestoreSyncService: User logged in (${user.uid}). Pulling cloud schedules & profiles...');
        await pullAndSyncAll();
        _listenToCloudChanges(onDataChanged);
      } else {
        debugPrint('FirestoreSyncService: User logged out. Cancelling realtime subscriptions.');
        _cancelSubscriptions();
      }
    });
  }

  /// Pull all cloud data and bidirectional merge with local Hive database
  Future<void> pullAndSyncAll() async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      // 0. Ensure user root document exists so it shows visibly in Firestore Console
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': user.displayName ?? 'User',
          'email': user.email ?? '',
          'lastSyncAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 1. Sync Schedules (Smart Two-Way Merge)
      final schedRef = _userSchedulesRef;
      if (schedRef != null) {
        final snapshot = await schedRef.get().timeout(const Duration(seconds: 10));
        final localSchedules = _scheduleRepo.getAllSchedules();

        final cloudEntries = <ScheduleEntry>[];
        final cloudIds = <String>{};

        for (final doc in snapshot.docs) {
          try {
            final entry = ScheduleEntry.fromJson(doc.data());
            cloudEntries.add(entry);
            cloudIds.add(entry.id);
          } catch (e) {
            debugPrint('Failed to parse cloud schedule doc ${doc.id}: $e');
          }
        }

        // A. Merge cloud entries into local Hive
        if (cloudEntries.isNotEmpty) {
          await _scheduleRepo.saveBatch(cloudEntries);
        }

        // B. Upload any local entries that are missing in the cloud (e.g. from Guest or Offline mode)
        final missingInCloud = localSchedules.where((e) => !cloudIds.contains(e.id)).toList();
        if (missingInCloud.isNotEmpty) {
          debugPrint('FirestoreSyncService: Uploading ${missingInCloud.length} offline/guest schedules to cloud...');
          await syncBatchSchedulesToCloud(missingInCloud);
        }
      }

      // 2. Sync Profiles (Smart Two-Way Merge)
      final profRef = _userProfilesRef;
      if (profRef != null) {
        final snapshot = await profRef.get().timeout(const Duration(seconds: 10));
        final localProfiles = _profileRepo.getAllProfiles();
        final cloudProfileIds = <String>{};

        for (final doc in snapshot.docs) {
          try {
            final profile = ScheduleProfile.fromJson(doc.data());
            cloudProfileIds.add(profile.id);
            await _profileRepo.saveProfile(profile);
          } catch (e) {
            debugPrint('Failed to parse cloud profile doc ${doc.id}: $e');
          }
        }

        // Upload any local profiles missing in cloud
        final missingProfiles = localProfiles.where((p) => !cloudProfileIds.contains(p.id)).toList();
        for (final p in missingProfiles) {
          await syncProfileToCloud(p);
        }
      }
    } catch (e) {
      debugPrint('FirestoreSyncService: Handled error/timeout during pullAndSyncAll: $e');
    }
  }

  void _listenToCloudChanges(VoidCallback? onDataChanged) {
    _cancelSubscriptions();

    final schedRef = _userSchedulesRef;
    if (schedRef != null) {
      _schedulesSubscription = schedRef.snapshots().listen((snapshot) async {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            try {
              final entry = ScheduleEntry.fromJson(data);
              await _scheduleRepo.saveSchedule(entry);
              changed = true;
            } catch (_) {}
          } else if (change.type == DocumentChangeType.removed) {
            await _scheduleRepo.deleteSchedule(change.doc.id);
            changed = true;
          }
        }
        if (changed && onDataChanged != null) {
          onDataChanged();
        }
      }, onError: (e) {
        debugPrint('FirestoreSyncService: Schedules realtime error: $e');
      });
    }

    final profRef = _userProfilesRef;
    if (profRef != null) {
      _profilesSubscription = profRef.snapshots().listen((snapshot) async {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            try {
              final profile = ScheduleProfile.fromJson(data);
              await _profileRepo.saveProfile(profile);
              changed = true;
            } catch (_) {}
          } else if (change.type == DocumentChangeType.removed) {
            await _profileRepo.deleteProfile(change.doc.id);
            changed = true;
          }
        }
        if (changed && onDataChanged != null) {
          onDataChanged();
        }
      }, onError: (e) {
        debugPrint('FirestoreSyncService: Profiles realtime error: $e');
      });
    }
  }

  /// Upload or update a single schedule entry to Cloud Firestore
  Future<void> syncScheduleToCloud(ScheduleEntry entry) async {
    final ref = _userSchedulesRef;
    if (ref == null) return;
    try {
      await ref.doc(entry.id).set(entry.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSyncService: Failed to sync schedule ${entry.id}: $e');
    }
  }

  /// Upload a batch of schedules to Cloud Firestore atomically
  Future<void> syncBatchSchedulesToCloud(List<ScheduleEntry> entries) async {
    final ref = _userSchedulesRef;
    if (ref == null || entries.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final entry in entries) {
        final docRef = ref.doc(entry.id);
        batch.set(docRef, entry.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('FirestoreSyncService: Synced ${entries.length} schedules to cloud batch.');
    } catch (e) {
      debugPrint('FirestoreSyncService: Failed batch upload: $e');
    }
  }

  /// Delete a schedule from Cloud Firestore
  Future<void> deleteScheduleFromCloud(String scheduleId) async {
    final ref = _userSchedulesRef;
    if (ref == null) return;
    try {
      await ref.doc(scheduleId).delete();
    } catch (e) {
      debugPrint('FirestoreSyncService: Failed to delete schedule $scheduleId: $e');
    }
  }

  /// Upload or update a profile to Cloud Firestore
  Future<void> syncProfileToCloud(ScheduleProfile profile) async {
    final ref = _userProfilesRef;
    if (ref == null) return;
    try {
      await ref.doc(profile.id).set(profile.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSyncService: Failed to sync profile ${profile.id}: $e');
    }
  }

  /// Delete a profile from Cloud Firestore
  Future<void> deleteProfileFromCloud(String profileId) async {
    final ref = _userProfilesRef;
    if (ref == null) return;
    try {
      await ref.doc(profileId).delete();
    } catch (e) {
      debugPrint('FirestoreSyncService: Failed to delete profile $profileId: $e');
    }
  }

  void _cancelSubscriptions() {
    _schedulesSubscription?.cancel();
    _schedulesSubscription = null;
    _profilesSubscription?.cancel();
    _profilesSubscription = null;
  }

  void dispose() {
    _cancelSubscriptions();
  }
}
