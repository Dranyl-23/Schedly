import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../providers/filter_providers.dart';

class WeekOverviewBar extends ConsumerWidget {
  const WeekOverviewBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weeklyCounts = ref.watch(weeklyScheduleCountsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate start of current week (Monday)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final dayDate = monday.add(Duration(days: index));
          final weekday = dayDate.weekday; // 1 = Mon, 7 = Sun
          final isSelected = selectedDate.year == dayDate.year &&
              selectedDate.month == dayDate.month &&
              selectedDate.day == dayDate.day;
          final isToday = now.year == dayDate.year &&
              now.month == dayDate.month &&
              now.day == dayDate.day;
          final count = weeklyCounts[weekday] ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedDateProvider.notifier).state =
                    DateTime(dayDate.year, dayDate.month, dayDate.day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isToday
                          ? (isDark ? AppColors.surfaceDark : Colors.blue.shade50)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday
                            // ignore: deprecated_member_use
                            ? AppColors.primary.withOpacity(0.4)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day abbreviation (Mon, Tue)
                    Text(
                      TimeUtils.getWeekdayShort(weekday),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            // ignore: deprecated_member_use
                            ? Colors.white.withOpacity(0.9)
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Day of month number (e.g. 25)
                    Text(
                      '${dayDate.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Schedule Count Dot
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: count > 0
                            ? (isSelected
                                ? Colors.white
                                : AppColors.primary)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
