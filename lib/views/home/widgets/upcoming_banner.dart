import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../models/schedule_category.dart';
import '../../../providers/filter_providers.dart';
import '../schedule_detail_view.dart';

class UpcomingBanner extends ConsumerWidget {
  const UpcomingBanner({super.key});

  IconData _getIconForSubject(String title, ScheduleCategory category) {
    final lower = title.toLowerCase();
    if (lower.contains('program') || lower.contains('code') || lower.contains('cs') || lower.contains('it')) {
      return Icons.computer_rounded;
    }
    if (lower.contains('math') || lower.contains('calc') || lower.contains('stat')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('data') || lower.contains('db') || lower.contains('sql')) {
      return Icons.storage_rounded;
    }
    if (lower.contains('duty') || lower.contains('medic') || lower.contains('nurs')) {
      return Icons.medical_services_rounded;
    }
    return category.icon;
  }

  String _calculateTimeRemaining(String startTimeStr) {
    try {
      final now = DateTime.now();
      final timeParts = startTimeStr.split(':');
      final startHour = int.parse(timeParts[0]);
      final startMinute = int.parse(timeParts[1]);

      final eventToday = DateTime(now.year, now.month, now.day, startHour, startMinute);
      final diff = eventToday.difference(now);

      if (diff.isNegative) {
        return 'In progress';
      }
      final totalMinutes = diff.inMinutes;
      if (totalMinutes < 60) {
        return 'in $totalMinutes min';
      } else {
        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        return 'in ${hours}h ${mins > 0 ? '${mins}m' : ''}';
      }
    } catch (_) {
      return 'Today';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingTodayScheduleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (upcoming == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All caught up today! 🎉',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No remaining scheduled events or shifts for today.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final remainingText = _calculateTimeRemaining(upcoming.startTime);
    final subjectIcon = _getIconForSubject(upcoming.title, upcoming.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3BB8),
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ScheduleDetailView(entry: upcoming)),
            );
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: NEXT SCHEDULE + in 35 min
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NEXT SCHEDULE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        remainingText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Content Row: Icon Box + Subject Title & Location
                Row(
                  children: [
                    // Frosted White/Blue Icon Box
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        subjectIcon,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upcoming.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 5),
                              Text(
                                '${TimeUtils.formatTo12Hour(upcoming.startTime)} – ${TimeUtils.formatTo12Hour(upcoming.endTime)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (upcoming.location != null && upcoming.location!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    upcoming.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
