import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  StreamSubscription<DocumentSnapshot>? _subscription;

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

          debugPrint('RemoteConfigService: Sync updated (Gemini Fallback: $geminiOnlineFallbackEnabled, Force Update: $forceUpdateEnabled)');
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
  }
}
