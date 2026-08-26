import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../models/schedule_category.dart';
import '../../../models/schedule_entry.dart';
import '../../calendar/widgets/weekly_timetable_grid.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleEntry entry;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onDelete;

  const ScheduleCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onToggleActive,
    this.onDelete,
  });

  IconData _getIconForSubject(String title, ScheduleCategory category) {
    final lower = title.toLowerCase();
    if (lower.contains('program') || lower.contains('code') || lower.contains('cs') || lower.contains('it') || lower.contains('software')) {
      return Icons.computer_rounded;
    }
    if (lower.contains('math') || lower.contains('calc') || lower.contains('stat') || lower.contains('algebra')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('data') || lower.contains('db') || lower.contains('sql') || lower.contains('network')) {
      return Icons.storage_rounded;
    }
    if (lower.contains('free') || lower.contains('break') || lower.contains('lunch') || lower.contains('vacant')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('duty') || lower.contains('medic') || lower.contains('nurs') || lower.contains('hospital')) {
      return Icons.medical_services_rounded;
    }
    return category.icon;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = TimetableTheme.forTitle(entry.title, isDark);
    final subjectIcon = _getIconForSubject(entry.title, entry.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Subject Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border, width: 1.2),
                  ),
                  child: Icon(
                    subjectIcon,
                    color: palette.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 10),

                // Connected Color Dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 10),

                // Subject Title, Time, and Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${TimeUtils.formatTo12Hour(entry.startTime)} – ${TimeUtils.formatTo12Hour(entry.endTime)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                        ),
                      ),
                      if (entry.location != null && entry.location!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 13, color: palette.primary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                entry.location!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing Chevron Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
