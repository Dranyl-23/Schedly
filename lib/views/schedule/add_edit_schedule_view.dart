import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';
import '../../providers/schedule_provider.dart';
import 'widgets/day_selector_chips.dart';
import 'widgets/reminder_picker.dart';

class AddEditScheduleView extends ConsumerStatefulWidget {
  final ScheduleEntry? initialEntry;

  const AddEditScheduleView({
    super.key,
    this.initialEntry,
  });

  @override
  ConsumerState<AddEditScheduleView> createState() => _AddEditScheduleViewState();
}

class _AddEditScheduleViewState extends ConsumerState<AddEditScheduleView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  late ScheduleCategory _selectedCategory;
  late List<int> _selectedDays;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _spansNextDay;
  late List<int> _reminders;

  bool get _isEditing => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');

    _selectedCategory = e?.category ?? ScheduleCategory.classSchedule;
    _selectedDays = e?.daysOfWeek ?? [DateTime.now().weekday];
    _startTime = e != null ? TimeUtils.stringToTimeOfDay(e.startTime) : const TimeOfDay(hour: 8, minute: 30);
    _endTime = e != null ? TimeUtils.stringToTimeOfDay(e.endTime) : const TimeOfDay(hour: 10, minute: 0);
    _spansNextDay = e?.spansNextDay ?? false;
    _reminders = e?.reminders ?? [_selectedCategory.defaultReminderLeadMinutes];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        // Auto-check spans overnight
        final startStr = TimeUtils.timeOfDayToString(_startTime);
        final endStr = TimeUtils.timeOfDayToString(_endTime);
        _spansNextDay = TimeUtils.checkSpansOvernight(startStr, endStr);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    final startStr = TimeUtils.timeOfDayToString(_startTime);
    final endStr = TimeUtils.timeOfDayToString(_endTime);

    final entry = ScheduleEntry(
      id: widget.initialEntry?.id,
      title: _titleController.text.trim(),
      category: _selectedCategory,
      daysOfWeek: _selectedDays,
      startTime: startStr,
      endTime: endStr,
      spansNextDay: _spansNextDay,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      reminders: _reminders,
      isActive: widget.initialEntry?.isActive ?? true,
      createdAt: widget.initialEntry?.createdAt,
      sourceImageId: widget.initialEntry?.sourceImageId,
    );

    final notifier = ref.read(scheduleListProvider.notifier);
    if (_isEditing) {
      await notifier.updateSchedule(entry);
    } else {
      await notifier.addSchedule(entry);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final startStr = TimeUtils.timeOfDayToString(_startTime);
    final endStr = TimeUtils.timeOfDayToString(_endTime);
    final durationText = TimeUtils.calculateDuration(startStr, endStr, spansNextDay: _spansNextDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedule' : 'New Schedule'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category Selector
            const Text(
              'CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ScheduleCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                          const SizedBox(width: 6),
                          Text(cat.displayName),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : null,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                            if (!_isEditing) {
                              _reminders = [cat.defaultReminderLeadMinutes];
                            }
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'SCHEDULE TITLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _selectedCategory == ScheduleCategory.classSchedule
                    ? 'e.g. IT 101 - Programming 1'
                    : (_selectedCategory == ScheduleCategory.workShift
                        ? 'e.g. Cashier Shift - Afternoon'
                        : 'e.g. Hospital ER Duty'),
                prefixIcon: const Icon(Icons.title_rounded, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a schedule title';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Days of the Week
            const Text(
              'DAYS OF THE WEEK',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            DaySelectorChips(
              selectedDays: _selectedDays,
              onChanged: (days) {
                setState(() {
                  _selectedDays = days;
                });
              },
            ),

            const SizedBox(height: 24),

            // Time Selection Card
            const Text(
              'TIME & DURATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Start Time
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickTime(isStart: true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'START TIME',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TimeUtils.formatTo12Hour(startStr),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.textSecondaryLight),
                      ),
                      // End Time
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickTime(isStart: false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'END TIME',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TimeUtils.formatTo12Hour(endStr),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Duration display & Spans next day toggle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Duration: $durationText',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text(
                            'Crosses midnight',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Checkbox(
                            value: _spansNextDay,
                            onChanged: (val) {
                              setState(() {
                                _spansNextDay = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Location
            const Text(
              'LOCATION / ROOM / STATION (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'e.g. Room 304, Mall Branch 1, ER Ward',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
            ),

            const SizedBox(height: 24),

            // Reminder Lead Times
            const Text(
              'REMINDER ALARMS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            ReminderPicker(
              selectedLeadMinutes: _reminders,
              onChanged: (updated) {
                setState(() {
                  _reminders = updated;
                });
              },
            ),

            const SizedBox(height: 24),

            // Notes
            const Text(
              'NOTES / PROFESSOR / SUPERVISOR (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Bring lab equipment, supervisor contact number...',
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save Changes' : 'Add to Schedule'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
