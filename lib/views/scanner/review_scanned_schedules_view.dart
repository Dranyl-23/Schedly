import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';
import '../../providers/profile_provider.dart';
import '../../providers/schedule_provider.dart';
import '../navigation/main_navigation_shell.dart';
import 'edit_scanned_entry_view.dart';

class ReviewScannedSchedulesView extends ConsumerStatefulWidget {
  final List<ScheduleEntry> initialEntries;

  const ReviewScannedSchedulesView({
    super.key,
    required this.initialEntries,
  });

  @override
  ConsumerState<ReviewScannedSchedulesView> createState() =>
      _ReviewScannedSchedulesViewState();
}

class _ReviewScannedSchedulesViewState
    extends ConsumerState<ReviewScannedSchedulesView> {
  late List<ScheduleEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.initialEntries);
  }

  void _onEditEntry(int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditScannedEntryView(entry: _entries[index]),
      ),
    );

    if (result != null && mounted) {
      if (result['deleted'] == true) {
        setState(() {
          _entries.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event removed from schedule')),
        );
      } else if (result['entry'] != null) {
        setState(() {
          _entries[index] = result['entry'] as ScheduleEntry;
        });
      }
    }
  }

  void _onSaveAll() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No schedule entries to save')),
      );
      return;
    }

    final activeProfile = ref.read(activeProfileProvider);
    final entriesToSave = _entries.map((e) {
      if (e.profileId == null && activeProfile != null) {
        return e.copyWith(profileId: activeProfile.id);
      }
      return e;
    }).toList();

    await ref.read(scheduleListProvider.notifier).addBatch(entriesToSave);

    if (mounted) {
      // Switch active tab to Timetable & Calendar so user immediately sees saved schedules
      ref.read(navigationIndexProvider.notifier).state = 1;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully saved ${entriesToSave.length} schedules! 🚀'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Color _getDayColor(int weekday) {
    switch (weekday) {
      case 1:
        return const Color(0xFF10B981); // MON - Green
      case 2:
        return const Color(0xFF2563EB); // TUE - Blue
      case 3:
        return const Color(0xFFF59E0B); // WED - Amber
      case 4:
        return const Color(0xFFF43F5E); // THU - Rose
      case 5:
        return const Color(0xFF06B6D4); // FRI - Cyan
      case 6:
        return const Color(0xFF8B5CF6); // SAT - Purple
      case 7:
        return const Color(0xFF6366F1); // SUN - Indigo
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _getDayAbbr(int weekday) {
    switch (weekday) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      case 7:
        return 'SUN';
      default:
        return 'DAY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Review & Edit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Summary Banner matching mockup
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We found ${_entries.length} schedules.',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Please review and edit before saving.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Scanned Schedules List
                    if (_entries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            'No schedule entries found.',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._entries.asMap().entries.map((item) {
                        final int index = item.key;
                        final ScheduleEntry entry = item.value;
                        final primaryDay = entry.daysOfWeek.isNotEmpty ? entry.daysOfWeek.first : 1;
                        final dayColor = _getDayColor(primaryDay);
                        final dayAbbr = _getDayAbbr(primaryDay);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Day Badge & Category Icon Column
                              Column(
                                children: [
                                  Text(
                                    dayAbbr,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: dayColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      entry.category.icon,
                                      color: dayColor,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 14),

                              // Middle: Title, Time, Location
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${TimeUtils.formatTo12Hour(entry.startTime)} – ${TimeUtils.formatTo12Hour(entry.endTime)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (entry.location != null && entry.location!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            entry.location!,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Right: Edit Button matching mockup
                              OutlinedButton(
                                onPressed: () => _onEditEntry(index),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: isDark ? Colors.transparent : Colors.white,
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Save Schedule Button matching mockup
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _onSaveAll,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    'Save Schedule (${_entries.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
