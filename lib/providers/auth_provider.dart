import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthState {
  final bool isOnboarded;
  final bool isLoggedIn;
  final String userName;
  final String userEmail;

  const AuthState({
    this.isOnboarded = false,
    this.isLoggedIn = false,
    this.userName = 'Dranyl Polacas',
    this.userEmail = 'dranyl@example.com',
  });

  AuthState copyWith({
    bool? isOnboarded,
    bool? isLoggedIn,
    String? userName,
    String? userEmail,
  }) {
    return AuthState(
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String settingsBox = 'app_settings_box';
  late Box _box;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(settingsBox);
    final onboarded = _box.get('isOnboarded', defaultValue: false) as bool;
    final loggedIn = _box.get('isLoggedIn', defaultValue: false) as bool;
    final name = _box.get('userName', defaultValue: 'Dranyl Polacas') as String;
    final email = _box.get('userEmail', defaultValue: 'dranyl@example.com') as String;

    state = AuthState(
      isOnboarded: onboarded,
      isLoggedIn: loggedIn,
      userName: name,
      userEmail: email,
    );
  }

  Future<void> completeOnboarding() async {
    await _box.put('isOnboarded', true);
    state = state.copyWith(isOnboarded: true);
  }

  Future<void> login({String? name, String? email}) async {
    final finalName = name ?? 'Dranyl Polacas';
    final finalEmail = email ?? 'dranyl@example.com';
    await _box.put('isLoggedIn', true);
    await _box.put('isOnboarded', true);
    await _box.put('userName', finalName);
    await _box.put('userEmail', finalEmail);

    state = state.copyWith(
      isLoggedIn: true,
      isOnboarded: true,
      userName: finalName,
      userEmail: finalEmail,
    );
  }

  Future<void> logout() async {
    await _box.put('isLoggedIn', false);
    state = state.copyWith(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
