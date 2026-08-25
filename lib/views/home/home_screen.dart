import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/utils/time_utils.dart';
import '../../models/schedule_category.dart';
import '../../providers/filter_providers.dart';
import '../../providers/schedule_provider.dart';
import '../scanner/scanner_landing_view.dart';
import '../schedule/add_edit_schedule_view.dart';
import '../settings/battery_optimization_view.dart';
import 'widgets/schedule_card.dart';
import 'widgets/upcoming_banner.dart';
import 'widgets/week_overview_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary),
                ),
                title: const Text(
                  'Scan Schedule Screenshot',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('AI extracts timetable from photo'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerLandingView()),
                  );
                },
              ),
              const Divider(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppColors.categoryWork.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, color: AppColors.categoryWork),
                ),
                title: const Text(
                  'Create Schedule Manually',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Enter subject or shift details by hand'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditScheduleView()),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDate = ref.watch(selectedDateProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final schedules = ref.watch(schedulesForSelectedDateProvider);
    final isToday = DateTime.now().year == selectedDate.year &&
        DateTime.now().month == selectedDate.month &&
        DateTime.now().day == selectedDate.day;

    final formattedDateHeader = isToday
        ? 'Today, ${DateFormat('MMM d').format(selectedDate)}'
        : '${TimeUtils.getWeekdayFull(selectedDate.weekday)}, ${DateFormat('MMM d').format(selectedDate)}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Scanner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            Text(
              formattedDateHeader,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Alarm Battery Setup Guide',
            icon: const Icon(Icons.battery_alert_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BatteryOptimizationView()),
              );
            },
          ),
          IconButton(
            tooltip: 'Quick Test Notification',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await NotificationService().showInstantNotification(
                title: '⏰ Schedule Scanner Test',
                body: 'Your alarm notifications are working perfectly!',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent! 🔔')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add / Scan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Next-Up Banner
          const SliverToBoxAdapter(
            child: UpcomingBanner(),
          ),

          // 7-day strip
          const SliverToBoxAdapter(
            child: WeekOverviewBar(),
          ),

          // Filter category chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedCategory == null,
                      onSelected: (_) {
                        ref.read(selectedCategoryFilterProvider.notifier).state = null;
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selectedCategory == null ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...ScheduleCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                          label: Text(cat.shortLabel),
                          selected: isSelected,
                          selectedColor: cat.color,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : null,
                          ),
                          onSelected: (selected) {
                            ref.read(selectedCategoryFilterProvider.notifier).state =
                                selected ? cat : null;
                          },
                        ),
                      );
                    }),
                  ],
                ),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No schedules for ${TimeUtils.getWeekdayFull(selectedDate.weekday)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the button below to scan a screenshot or add an event manually.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => _showAddOptions(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Schedule'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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
                            builder: (_) => AddEditScheduleView(initialEntry: entry),
                          ),
                        );
                      },
                      onToggleActive: (val) {
                        ref.read(scheduleListProvider.notifier).toggleActive(entry.id);
                      },
                      onDelete: () {
                        ref.read(scheduleListProvider.notifier).deleteSchedule(entry);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted "${entry.title}"'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                ref.read(scheduleListProvider.notifier).addSchedule(entry);
                              },
                            ),
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
