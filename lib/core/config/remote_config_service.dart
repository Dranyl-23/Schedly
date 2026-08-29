import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_version.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  bool geminiOnlineFallbackEnabled = true;
  String minRequiredAppVersion = '1.0.0+8';
  String latestAppVersion = '1.0.0+8';
  bool forceUpdateEnabled = false;
  String updateStoreUrl = 'https://github.com/Dranyl-23/Schedly/releases';
  bool maintenanceMode = false;
  String maintenanceMessage = '';

  final ValueNotifier<bool> updateRequiredNotifier = ValueNotifier<bool>(false);

  StreamSubscription<DocumentSnapshot>? _subscription;

  static int parseBuildNumber(String version) {
    if (version.contains('+')) {
      final parts = version.split('+');
      return int.tryParse(parts.last) ?? 0;
    }
    return int.tryParse(version) ?? 0;
  }

  bool get isUpdateRequired {
    if (!forceUpdateEnabled) return false;
    final currentBuild = parseBuildNumber(AppVersion.buildNumber);
    final minBuild = parseBuildNumber(minRequiredAppVersion);
    return currentBuild < minBuild;
  }

  void startListening() {
    try {
      final firestore = FirebaseFirestore.instance;
      _subscription = firestore
          .collection('system_config')
          .doc('app_control')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          geminiOnlineFallbackEnabled = data['geminiOnlineFallbackEnabled'] as bool? ?? true;
          minRequiredAppVersion = data['minRequiredAppVersion'] as String? ?? '1.0.0+8';
          latestAppVersion = data['latestAppVersion'] as String? ?? '1.0.0+8';
          forceUpdateEnabled = data['forceUpdateEnabled'] as bool? ?? false;
          updateStoreUrl = data['updateStoreUrl'] as String? ?? 'https://github.com/Dranyl-23/Schedly/releases';
          maintenanceMode = data['maintenanceMode'] as bool? ?? false;
          maintenanceMessage = data['maintenanceMessage'] as String? ?? '';

          updateRequiredNotifier.value = isUpdateRequired;

          debugPrint('RemoteConfigService: Sync updated (Force: $forceUpdateEnabled, Required: $isUpdateRequired, Min: $minRequiredAppVersion, Current: ${AppVersion.buildNumber})');
        }
      }, onError: (err) {
        debugPrint('RemoteConfigService: Listener notice ($err)');
      });
    } catch (e) {
      debugPrint('RemoteConfigService: Init error ($e)');
    }
  }

  void dispose() {
    _subscription?.cancel();
    updateRequiredNotifier.dispose();
  }
}
