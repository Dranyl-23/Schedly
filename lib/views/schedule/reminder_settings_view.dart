import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../models/schedule_entry.dart';
import '../../providers/schedule_provider.dart';

class ReminderSettingsView extends ConsumerStatefulWidget {
  final ScheduleEntry entry;

  const ReminderSettingsView({
    super.key,
    required this.entry,
  });

  @override
  ConsumerState<ReminderSettingsView> createState() => _ReminderSettingsViewState();
}

class _ReminderSettingsViewState extends ConsumerState<ReminderSettingsView> {
  late bool _enableReminder;
  late int _selectedLeadMinutes;
  bool _smartReminder = false;

  @override
  void initState() {
    super.initState();
    _enableReminder = widget.entry.reminders.isNotEmpty;
    _selectedLeadMinutes =
        widget.entry.reminders.isNotEmpty ? widget.entry.reminders.first : 15;
  }

  String _calculateNotificationPreviewTime() {
    final parts = widget.entry.startTime.split(':');
    if (parts.length != 2) return widget.entry.startTime;

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]) - _selectedLeadMinutes;

    while (minute < 0) {
      minute += 60;
      hour -= 1;
    }
    if (hour < 0) hour += 24;

    final formattedHour = hour.toString().padLeft(2, '0');
    final formattedMinute = minute.toString().padLeft(2, '0');
    return TimeUtils.formatTo12Hour('$formattedHour:$formattedMinute');
  }

  Future<void> _save() async {
    final updatedReminders = _enableReminder ? [_selectedLeadMinutes] : <int>[];
    final updated = widget.entry.copyWith(reminders: updatedReminders);

    await ref.read(scheduleListProvider.notifier).updateSchedule(updated);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder preferences updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifPreviewTime = _calculateNotificationPreviewTime();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Enable Reminder Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Enable Reminder',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _enableReminder,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    setState(() => _enableReminder = val);
                  },
                ),
              ],
            ),
          ),

          if (_enableReminder) ...[
            const SizedBox(height: 16),

            // Remind Me Dropdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remind me',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedLeadMinutes,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('At exact start time')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                      DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                      DropdownMenuItem(value: 60, child: Text('1 hour before')),
                      DropdownMenuItem(value: 120, child: Text('2 hours before')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLeadMinutes = val);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Smart Reminder Switch
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Reminder (Recommended)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get reminded based on your location and traffic estimation.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: _smartReminder,
                    activeThumbColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      setState(() => _smartReminder = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live Preview Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Soft light blue
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOTIFICATION PREVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be notified at $notifPreviewTime ahead of ${widget.entry.title}.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
