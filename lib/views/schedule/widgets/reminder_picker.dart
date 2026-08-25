import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_utils.dart';

class ReminderPicker extends StatelessWidget {
  final List<int> selectedLeadMinutes;
  final ValueChanged<List<int>> onChanged;

  const ReminderPicker({
    super.key,
    required this.selectedLeadMinutes,
    required this.onChanged,
  });

  static const List<int> presetMinutes = [0, 10, 15, 30, 60, 120];

  void _toggleMinute(int min) {
    final updated = List<int>.from(selectedLeadMinutes);
    if (updated.contains(min)) {
      if (updated.length > 1) {
        updated.remove(min);
      }
    } else {
      updated.add(min);
    }
    updated.sort();
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presetMinutes.map((min) {
        final isSelected = selectedLeadMinutes.contains(min);

        return FilterChip(
          label: Text(TimeUtils.formatLeadMinutes(min)),
          selected: isSelected,
          showCheckmark: isSelected,
          checkmarkColor: isSelected ? Colors.white : null,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: (_) => _toggleMinute(min),
        );
      }).toList(),
    );
  }
}
