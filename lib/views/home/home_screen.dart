import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filter_providers.dart';
import '../../providers/notification_center_provider.dart';
import '../../providers/user_setup_provider.dart';
import '../navigation/main_navigation_shell.dart';
import 'notifications_screen.dart';
import 'schedule_detail_view.dart';
import 'widgets/announcement_banner.dart';
import 'widgets/schedule_card.dart';
import 'widgets/schedule_summary_modal.dart';
import 'widgets/upcoming_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final schedules = ref.watch(schedulesForTodayProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final userSetup = ref.watch(userSetupProvider);

    String todaySectionTitle;
    String noTodayTitle;
    String upcomingRoleNoun;

    switch (userSetup.role.toLowerCase()) {
      case 'duty':
      case 'medic':
      case 'nurs':
        todaySectionTitle = "TODAY'S CLINICAL DUTY";
        noTodayTitle = 'No duty shifts scheduled for today';
        upcomingRoleNoun = 'clinical duty';
        break;
      case 'work':
      case 'job':
      case 'part':
        todaySectionTitle = "TODAY'S WORK SHIFTS";
        noTodayTitle = 'No work shifts scheduled for today';
        upcomingRoleNoun = 'work shift';
        break;
      case 'personal':
      case 'custom':
        todaySectionTitle = "TODAY'S TIMETABLE";
        noTodayTitle = 'No scheduled routine for today';
        upcomingRoleNoun = 'routine';
        break;
      default:
        todaySectionTitle = "TODAY'S SCHEDULE";
        noTodayTitle = 'No classes scheduled for today';
        upcomingRoleNoun = 'class';
    }

    // Extract first name (e.g. "Alfie" or "Dranyl")
    final firstName = auth.userName.trim().split(' ').first;
    final greeting = '${_getGreeting()}, $firstName!';
    final fullFormattedDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 24),
          tooltip: 'Schedule Insights & Export',
          onPressed: () {
            ScheduleSummaryModal.show(context);
          },
        ),
        title: const Text(
          'Reminda',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E3A8A),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 24),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Greeting & Date Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fullFormattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Remote In-App Announcement Broadcast Banner
          const SliverToBoxAdapter(
            child: AnnouncementBanner(),
          ),

          // Hero Next Schedule Banner (with Live Dynamic Countdown across any day)
          const SliverToBoxAdapter(
            child: UpcomingBanner(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 14),
          ),

          // Role-Adaptive Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    todaySectionTitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(navigationIndexProvider.notifier).state = 1; // Switch to Calendar / Timetable tab
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Schedule List or Empty State
          if (schedules.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final nextUpcoming = ref.watch(nextUpcomingAcrossAllDaysProvider);

                      if (nextUpcoming != null) {
                        final dayText = nextUpcoming.daysDifference == 1
                            ? 'Tomorrow'
                            : DateFormat('EEEE, MMM d').format(nextUpcoming.targetDateTime);

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                size: 48,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              noTodayTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Your upcoming $upcomingRoleNoun for "${nextUpcoming.entry.title}" starts on $dayText at ${TimeUtils.formatTo12Hour(nextUpcoming.entry.startTime)}.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 48,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No schedules added yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "+" below to scan or add classes & shifts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = schedules[index];
                    return ScheduleCard(
                      entry: entry,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleDetailView(entry: entry),
                          ),
                        );
                      },
                    );
                  },
                  childCount: schedules.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
