import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/schedule_entry.dart';
import '../constants/app_version.dart';
import '../database/firestore_instance.dart';

class AiTrainingTelemetryService {
  static const String settingsBox = 'app_settings_box';
  static const String contributeKey = 'contribute_ai_training_data';

  /// Check if user has opted-in to anonymous AI training telemetry (default true)
  static bool isTelemetryEnabled() {
    try {
      if (Hive.isBoxOpen(settingsBox)) {
        return Hive.box(settingsBox).get(contributeKey, defaultValue: true) as bool;
      }
    } catch (_) {}
    return true;
  }

  /// Toggle user consent
  static Future<void> setTelemetryEnabled(bool enabled) async {
    try {
      final box = Hive.isBoxOpen(settingsBox)
          ? Hive.box(settingsBox)
          : await Hive.openBox(settingsBox);
      await box.put(contributeKey, enabled);
    } catch (e) {
      debugPrint('AiTrainingTelemetryService: Failed to save consent: $e');
    }
  }

  /// Anonymously record user-verified ground-truth schedule sample for future offline AI training
  static Future<void> recordGroundTruthSample({
    required List<ScheduleEntry> entries,
    String? rawOcrText,
    String? institutionName,
    String? role,
    String source = 'offline_mlkit',
  }) async {
    if (!isTelemetryEnabled()) return;
    if (entries.isEmpty) return;

    try {
      final sampleEntries = entries.map((e) => {
        'title': e.title,
        'daysOfWeek': e.daysOfWeek,
        'startTime': e.startTime,
        'endTime': e.endTime,
        'location': e.location ?? '',
        'category': e.category.name,
        'notes': e.notes ?? '',
      }).toList();

      final payload = {
        'entriesCount': entries.length,
        'verifiedEntries': sampleEntries,
        'rawOcrText': rawOcrText ?? '',
        'institutionName': institutionName ?? '',
        'role': role ?? 'general',
        'engineSource': source,
        'appVersion': AppVersion.fullVersion,
        'platform': Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Other'),
        'timestamp': FieldValue.serverTimestamp(),
        'createdAtIso': DateTime.now().toIso8601String(),
      };

      // Non-blocking fire-and-forget background write to Firestore
      appFirestore.collection('ai_training_samples').add(payload).ignore();
    } catch (e) {
      debugPrint('AiTrainingTelemetryService: Telemetry background sync ignored: $e');
    }
  }
}
