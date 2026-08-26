import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/config/app_config.dart';

class AuthState {
  final bool isOnboarded;
  final bool isLoggedIn;
  final bool isGuest;
  final bool isLoading;
  final String? errorMessage;
  final String? userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  const AuthState({
    this.isOnboarded = false,
    this.isLoggedIn = false,
    this.isGuest = false,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
    this.userName = 'Guest User',
    this.userEmail = '',
    this.userPhotoUrl,
  });

  AuthState copyWith({
    bool? isOnboarded,
    bool? isLoggedIn,
    bool? isGuest,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
  }) {
    return AuthState(
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isGuest: isGuest ?? this.isGuest,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String settingsBox = 'app_settings_box';
  late Box _box;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConfig.googleOAuthClientId.isNotEmpty
        ? AppConfig.googleOAuthClientId
        : null,
  );
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(settingsBox);
    final onboarded = _box.get('isOnboarded', defaultValue: false) as bool;
    final isGuestMode = _box.get('isGuestLogin', defaultValue: false) as bool;
    final cachedName = _box.get('userName', defaultValue: isGuestMode ? 'Guest User' : 'Dranyl Polacas') as String;
    final cachedEmail = _box.get('userEmail', defaultValue: isGuestMode ? '' : 'dranyl@example.com') as String;
    final cachedPhoto = _box.get('userPhotoUrl') as String?;

    final currentUser = _firebaseAuth.currentUser;
    final loggedIn = currentUser != null || isGuestMode || (_box.get('isLoggedIn', defaultValue: false) as bool);

    state = AuthState(
      isOnboarded: onboarded,
      isLoggedIn: loggedIn,
      isGuest: isGuestMode,
      userId: currentUser?.uid,
      userName: currentUser?.displayName ?? cachedName,
      userEmail: currentUser?.email ?? cachedEmail,
      userPhotoUrl: currentUser?.photoURL ?? cachedPhoto,
    );

    // Listen to Firebase Auth state changes in realtime
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        final name = user.displayName ?? (user.email?.split('@').first ?? 'User');
        final email = user.email ?? 'user@example.com';
        final photo = user.photoURL;

        await _box.put('isGuestLogin', false);
        await _box.put('isLoggedIn', true);
        await _box.put('userName', name);
        await _box.put('userEmail', email);
        if (photo != null) await _box.put('userPhotoUrl', photo);

        state = state.copyWith(
          isLoggedIn: true,
          isGuest: false,
          isOnboarded: true,
          userId: user.uid,
          userName: name,
          userEmail: email,
          userPhotoUrl: photo,
          isLoading: false,
          clearError: true,
        );
      } else {
        final wasGuest = _box.get('isGuestLogin', defaultValue: false) as bool;
        if (!wasGuest) {
          await _box.put('isLoggedIn', false);
          state = state.copyWith(
            isLoggedIn: false,
            isGuest: false,
            userId: null,
            isLoading: false,
          );
        }
      }
    });
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> completeOnboarding() async {
    await _box.put('isOnboarded', true);
    state = state.copyWith(isOnboarded: true);
  }

  /// Sign In with Email & Password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final name = user.displayName ?? (user.email?.split('@').first ?? 'User');
        await _box.put('isGuestLogin', false);
        await _box.put('isLoggedIn', true);
        await _box.put('isOnboarded', true);
        await _box.put('userName', name);
        await _box.put('userEmail', user.email ?? email);

        state = state.copyWith(
          isLoggedIn: true,
          isGuest: false,
          isOnboarded: true,
          userId: user.uid,
          userName: name,
          userEmail: user.email ?? email,
          userPhotoUrl: user.photoURL,
          isLoading: false,
          clearError: true,
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code, e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  /// Register new user with Email, Password, and Display Name
  Future<bool> registerWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final name = displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : (user.email?.split('@').first ?? 'User');

        await user.updateDisplayName(name);
        await _box.put('isGuestLogin', false);
        await _box.put('isLoggedIn', true);
        await _box.put('isOnboarded', true);
        await _box.put('userName', name);
        await _box.put('userEmail', user.email ?? email);

        state = state.copyWith(
          isLoggedIn: true,
          isGuest: false,
          isOnboarded: true,
          userId: user.uid,
          userName: name,
          userEmail: user.email ?? email,
          isLoading: false,
          clearError: true,
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code, e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create account. Please try again.',
      );
      return false;
    }
  }

  /// Sign In with Google OAuth
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled Google picker
        state = state.copyWith(isLoading: false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final name = user.displayName ?? googleUser.displayName ?? 'Google User';
        final email = user.email ?? googleUser.email;
        final photo = user.photoURL ?? googleUser.photoUrl;

        await _box.put('isGuestLogin', false);
        await _box.put('isLoggedIn', true);
        await _box.put('isOnboarded', true);
        await _box.put('userName', name);
        await _box.put('userEmail', email);
        if (photo != null) await _box.put('userPhotoUrl', photo);

        state = state.copyWith(
          isLoggedIn: true,
          isGuest: false,
          isOnboarded: true,
          userId: user.uid,
          userName: name,
          userEmail: email,
          userPhotoUrl: photo,
          isLoading: false,
          clearError: true,
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code, e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google Sign-In failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Offline / Guest Login Mode
  Future<void> loginAsGuest({String? name, String? email}) async {
    final finalName = name ?? 'Guest User';
    final finalEmail = email ?? '';
    await _box.put('isGuestLogin', true);
    await _box.put('isLoggedIn', true);
    await _box.put('isOnboarded', true);
    await _box.put('userName', finalName);
    await _box.put('userEmail', finalEmail);

    state = state.copyWith(
      isLoggedIn: true,
      isGuest: true,
      isOnboarded: true,
      userName: finalName,
      userEmail: finalEmail,
      userId: null,
      userPhotoUrl: null,
      isLoading: false,
      clearError: true,
    );
  }

  /// Logout from Firebase and local state
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}

    await _box.put('isGuestLogin', false);
    await _box.put('isLoggedIn', false);

    state = state.copyWith(
      isLoggedIn: false,
      isGuest: false,
      userId: null,
      isLoading: false,
      clearError: true,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _mapFirebaseError(String code, String? defaultMsg) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return defaultMsg ?? 'Authentication failed ($code).';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
