import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../calendar/calendar_view_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../profiles/schedule_profiles_view.dart';
import '../schedule/widgets/add_schedule_modal_dialog.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  void _showAddModal(BuildContext context) {
    AddScheduleModalDialog.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final List<Widget> screens = [
      const HomeScreen(),
      const CalendarViewScreen(),
      const ScheduleProfilesView(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 64 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Home
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              isDark: isDark,
              onTap: () => ref.read(navigationIndexProvider.notifier).state = 0,
            ),

            // Tab 1: Calendar / Timetable
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              selectedIcon: Icons.calendar_month_rounded,
              label: 'Calendar',
              isSelected: currentIndex == 1,
              isDark: isDark,
              onTap: () => ref.read(navigationIndexProvider.notifier).state = 1,
            ),

            // Center Action Button (+)
            GestureDetector(
              onTap: () => _showAddModal(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // Tab 2: Schedules (My Schedule Sets)
            _buildNavItem(
              context: context,
              icon: Icons.view_agenda_outlined,
              selectedIcon: Icons.view_agenda_rounded,
              label: 'Schedules',
              isSelected: currentIndex == 2,
              isDark: isDark,
              onTap: () => ref.read(navigationIndexProvider.notifier).state = 2,
            ),

            // Tab 3: More (Account, Sync & App Preferences)
            _buildNavItem(
              context: context,
              icon: Icons.more_horiz_rounded,
              selectedIcon: Icons.more_horiz_rounded,
              label: 'More',
              isSelected: currentIndex == 3,
              isDark: isDark,
              onTap: () => ref.read(navigationIndexProvider.notifier).state = 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF2563EB);
    final inactiveColor = isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
