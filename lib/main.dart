import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/remote_config_service.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_version.dart';
import 'core/database/institution_sync_service.dart';
import 'core/database/profile_repository.dart';
import 'core/database/schedule_repository.dart';
import 'core/database/user_sync_service.dart';
import 'core/notifications/notification_service.dart';
import 'firebase_options.dart';
import 'providers/profile_provider.dart';
import 'providers/schedule_provider.dart';
import 'views/onboarding/splash_screen.dart';

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize App Version from pubspec / platform package info
  await AppVersion.initialize();

  // 1. Load Environment Variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env: $e');
  }

  // 2. Initialize Firebase, Cloud Directory & Remote Config Flags
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  InstitutionSyncService().startListening();
  RemoteConfigService.instance.startListening();
  UserSyncService.instance.syncCurrentUser();

  // 2. Initialize Local Databases (Schedules + Profiles)
  final repository = ScheduleRepository();
  await repository.init();

  final profileRepository = ProfileRepository();
  await profileRepository.init();

  // 3. Initialize Notification and Alarm Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // 4. Ensure all active alarms are registered in OS AlarmManager upon app start
  final allSavedSchedules = repository.getAllSchedules();
  if (allSavedSchedules.isNotEmpty) {
    await notificationService.rescheduleAll(allSavedSchedules);
  }

  runApp(
    ProviderScope(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(repository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const RemindaApp(),
    ),
  );
}

class RemindaApp extends StatelessWidget {
  const RemindaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
