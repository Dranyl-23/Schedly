import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/database/profile_repository.dart';
import 'core/database/schedule_repository.dart';
import 'core/notifications/notification_service.dart';
import 'models/schedule_category.dart';
import 'models/schedule_entry.dart';
import 'providers/profile_provider.dart';
import 'providers/schedule_provider.dart';
import 'views/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Databases (Schedules + Profiles)
  final repository = ScheduleRepository();
  await repository.init();

  final profileRepository = ProfileRepository();
  await profileRepository.init();

  // 2. Initialize Notification and Alarm Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // 3. Seed welcome demo items if first launch (matching storyboard)
  if (repository.getAllSchedules().isEmpty) {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Mon .. 7 = Sun

    final welcomeEntries = [
      ScheduleEntry(
        title: 'Math 101',
        category: ScheduleCategory.classSchedule,
        daysOfWeek: [1, 3, 5, todayWeekday], // Mon, Wed, Fri + Today
        startTime: '08:00',
        endTime: '09:30',
        location: 'Room 302',
        notes: 'Bring calculator and notebook.',
        reminders: [15],
      ),
      ScheduleEntry(
        title: 'Break',
        category: ScheduleCategory.custom,
        daysOfWeek: [1, 3, 5, todayWeekday],
        startTime: '09:30',
        endTime: '10:00',
        location: 'Campus Courtyard',
        reminders: [5],
      ),
      ScheduleEntry(
        title: 'Physics 201',
        category: ScheduleCategory.classSchedule,
        daysOfWeek: [1, 3, 5, todayWeekday],
        startTime: '10:00',
        endTime: '11:30',
        location: 'Room 201',
        notes: 'Laboratory experiment submission',
        reminders: [15],
      ),
      ScheduleEntry(
        title: 'Lunch Break',
        category: ScheduleCategory.custom,
        daysOfWeek: [1, 2, 3, 4, 5, todayWeekday],
        startTime: '11:30',
        endTime: '12:30',
        location: 'Student Lounge / Canteen',
        reminders: [],
      ),
      ScheduleEntry(
        title: 'Eng 101',
        category: ScheduleCategory.classSchedule,
        daysOfWeek: [2, 4],
        startTime: '13:00',
        endTime: '14:30',
        location: 'Room 105',
        notes: 'Purposive Communication recitation',
        reminders: [15],
      ),
      ScheduleEntry(
        title: 'Evening Cashier Shift',
        category: ScheduleCategory.workShift,
        daysOfWeek: [5, 6],
        startTime: '16:00',
        endTime: '22:00',
        location: 'Store Branch 2',
        notes: 'Supervisor: Mark',
        reminders: [60, 15],
      ),
    ];

    await repository.saveBatch(welcomeEntries);
    for (final entry in welcomeEntries) {
      await notificationService.scheduleEntryReminders(entry);
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(repository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const SchedlyApp(),
    ),
  );
}

class SchedlyApp extends StatelessWidget {
  const SchedlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
