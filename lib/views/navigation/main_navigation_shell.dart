import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../calendar/calendar_view_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../profiles/schedule_profiles_view.dart';
import '../scanner/import_schedule_view.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 58,
        width: 58,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScheduleView()),
            );
          },
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  ref: ref,
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isDark: isDark,
                ),
                _buildNavItem(
                  ref: ref,
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.calendar_today_rounded,
                  label: 'Calendar',
                  isDark: isDark,
                ),
                const SizedBox(width: 48), // Spacer for central FAB
                _buildNavItem(
                  ref: ref,
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.grid_view_rounded,
                  label: 'Schedules',
                  isDark: isDark,
                ),
                _buildNavItem(
                  ref: ref,
                  index: 3,
                  currentIndex: currentIndex,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected
        ? const Color(0xFF2563EB)
        : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8));

    return InkWell(
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
