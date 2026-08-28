import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_utils.dart';

class DaySelectorChips extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const DaySelectorChips({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  void _toggleDay(int day) {
    final updated = List<int>.from(selectedDays);
    if (updated.contains(day)) {
      if (updated.length > 1) {
        updated.remove(day);
      }
    } else {
      updated.add(day);
    }
    updated.sort();
    onChanged(updated);
  }

  void _applyPreset(List<int> preset) {
    onChanged(List<int>.from(preset)..sort());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 7 Day circles/pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = index + 1; // 1 = Mon .. 7 = Sun
            final isSelected = selectedDays.contains(day);

            return GestureDetector(
              onTap: () => _toggleDay(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  TimeUtils.getWeekdayShort(day),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        // Quick Presets Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip('MWF', [1, 3, 5], isDark),
              const SizedBox(width: 6),
              _buildPresetChip('TTH', [2, 4], isDark),
              const SizedBox(width: 6),
              _buildPresetChip('Weekdays (M-F)', [1, 2, 3, 4, 5], isDark),
              const SizedBox(width: 6),
              _buildPresetChip('Weekends', [6, 7], isDark),
              const SizedBox(width: 6),
              _buildPresetChip('Everyday', [1, 2, 3, 4, 5, 6, 7], isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, List<int> presetDays, bool isDark) {
    final isMatching = selectedDays.length == presetDays.length &&
        selectedDays.every((d) => presetDays.contains(d));

    return InkWell(
      onTap: () => _applyPreset(presetDays),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isMatching
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMatching ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isMatching
                ? AppColors.primary
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
