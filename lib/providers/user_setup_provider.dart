import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/schedule_profile.dart';
import 'profile_provider.dart';
import 'sound_settings_provider.dart';

class UserSetupState {
  final bool isSetupCompleted;
  final String role;
  final String countryCode;
  final String regionCode;
  final String city;
  final String organizationName;
  final String organizationShort;
  final String organizationColorHex;
  final String selectedToneId;
  final int reminderLeadMinutes;

  const UserSetupState({
    this.isSetupCompleted = false,
    this.role = 'school',
    this.countryCode = 'PH',
    this.regionCode = 'R11',
    this.city = 'Digos City',
    this.organizationName = 'University of Mindanao (UM Digos College)',
    this.organizationShort = 'UM Digos',
    this.organizationColorHex = '#DC2626',
    this.selectedToneId = 'crystal_chime',
    this.reminderLeadMinutes = 15,
  });

  UserSetupState copyWith({
    bool? isSetupCompleted,
    String? role,
    String? countryCode,
    String? regionCode,
    String? city,
    String? organizationName,
    String? organizationShort,
    String? organizationColorHex,
    String? selectedToneId,
    int? reminderLeadMinutes,
  }) {
    return UserSetupState(
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      role: role ?? this.role,
      countryCode: countryCode ?? this.countryCode,
      regionCode: regionCode ?? this.regionCode,
      city: city ?? this.city,
      organizationName: organizationName ?? this.organizationName,
      organizationShort: organizationShort ?? this.organizationShort,
      organizationColorHex: organizationColorHex ?? this.organizationColorHex,
      selectedToneId: selectedToneId ?? this.selectedToneId,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
    );
  }
}

class UserSetupNotifier extends StateNotifier<UserSetupState> {
  static const String settingsBox = 'app_settings_box';
  Box? _box;

  UserSetupNotifier() : super(const UserSetupState()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(settingsBox);
    final completed = _box?.get('isSetupCompleted', defaultValue: false) as bool;
    final role      = _box?.get('userRole', defaultValue: 'school') as String;
    final country   = _box?.get('userCountry', defaultValue: 'PH') as String;
    final region    = _box?.get('userRegionCode', defaultValue: 'R11') as String;
    final city      = _box?.get('userCity', defaultValue: 'Digos City') as String;
    final orgName   = _box?.get('userOrgName', defaultValue: 'University of Mindanao (UM Digos College)') as String;
    final orgShort  = _box?.get('userOrgShort', defaultValue: 'UM Digos') as String;
    final orgColor  = _box?.get('userOrgColor', defaultValue: '#DC2626') as String;
    final toneId    = _box?.get('default_alarm_tone_id', defaultValue: 'crystal_chime') as String;
    final leadMins  = _box?.get('defaultReminderLead', defaultValue: 15) as int;

    state = UserSetupState(
      isSetupCompleted: completed,
      role: role,
      countryCode: country,
      regionCode: region,
      city: city,
      organizationName: orgName,
      organizationShort: orgShort,
      organizationColorHex: orgColor,
      selectedToneId: toneId,
      reminderLeadMinutes: leadMins,
    );
  }

  void updateRole(String role) => state = state.copyWith(role: role);

  void updateCountry(String countryCode) => state = state.copyWith(
    countryCode: countryCode, regionCode: '', city: '',
    organizationName: '', organizationShort: '',
  );

  void updateRegion(String regionCode) => state = state.copyWith(
    regionCode: regionCode, city: '',
    organizationName: '', organizationShort: '',
  );

  void updateCity(String city) => state = state.copyWith(
    city: city, organizationName: '', organizationShort: '',
  );

  void updateOrganization({
    required String name,
    required String shortName,
    required String colorHex,
  }) {
    state = state.copyWith(
      organizationName: name,
      organizationShort: shortName,
      organizationColorHex: colorHex,
    );
  }

  void updateTone(String toneId) => state = state.copyWith(selectedToneId: toneId);
  void updateReminderLead(int minutes) => state = state.copyWith(reminderLeadMinutes: minutes);

  Future<void> completeSetup(WidgetRef ref) async {
    try {
      _box = Hive.isBoxOpen(settingsBox)
          ? Hive.box(settingsBox)
          : await Hive.openBox(settingsBox);

      await _box?.put('isSetupCompleted', true);
      await _box?.put('userRole', state.role);
      await _box?.put('userCountry', state.countryCode);
      await _box?.put('userRegionCode', state.regionCode);
      await _box?.put('userCity', state.city);
      await _box?.put('userOrgName', state.organizationName);
      await _box?.put('userOrgShort', state.organizationShort);
      await _box?.put('userOrgColor', state.organizationColorHex);
      await _box?.put('default_alarm_tone_id', state.selectedToneId);
      await _box?.put('defaultReminderLead', state.reminderLeadMinutes);
    } catch (_) {}

    state = state.copyWith(isSetupCompleted: true);

    try {
      await ref.read(soundSettingsProvider.notifier).selectTone(state.selectedToneId);
    } catch (_) {}

    try {
      final profileName = state.organizationShort.isNotEmpty
          ? '${state.organizationShort} Schedule'
          : state.organizationName.isNotEmpty
              ? '${state.organizationName} Schedule'
              : 'My Schedule';

      final initialProfile = ScheduleProfile(
        name: profileName,
        type: state.role,
        colorHex: state.organizationColorHex,
        isActive: true,
      );

      await ref.read(profileListProvider.notifier).addProfile(initialProfile);
      await ref.read(profileListProvider.notifier).setActive(initialProfile.id);
    } catch (_) {}

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': state.role,
          'countryCode': state.countryCode,
          'regionCode': state.regionCode,
          'city': state.city,
          'organizationName': state.organizationName,
          'organizationShort': state.organizationShort,
          'defaultToneId': state.selectedToneId,
          'defaultReminderLead': state.reminderLeadMinutes,
          'setupCompletedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).ignore(); // non-blocking background sync
      }
    } catch (_) {}
  }
}

final userSetupProvider =
    StateNotifierProvider<UserSetupNotifier, UserSetupState>((ref) {
  return UserSetupNotifier();
});
