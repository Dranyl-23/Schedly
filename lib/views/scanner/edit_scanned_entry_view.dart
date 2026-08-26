import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';

class EditScannedEntryView extends StatefulWidget {
  final ScheduleEntry entry;

  const EditScannedEntryView({super.key, required this.entry});

  @override
  State<EditScannedEntryView> createState() => _EditScannedEntryViewState();
}

class _EditScannedEntryViewState extends State<EditScannedEntryView> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  late ScheduleCategory _selectedCategory;
  late List<int> _selectedDays;
  late String _startTime;
  late String _endTime;
  late int _selectedReminderLead;

  final List<Map<String, dynamic>> _weekdays = [
    {'day': 1, 'name': 'Monday'},
    {'day': 2, 'name': 'Tuesday'},
    {'day': 3, 'name': 'Wednesday'},
    {'day': 4, 'name': 'Thursday'},
    {'day': 5, 'name': 'Friday'},
    {'day': 6, 'name': 'Saturday'},
    {'day': 7, 'name': 'Sunday'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _locationController = TextEditingController(text: widget.entry.location ?? '');
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _selectedCategory = widget.entry.category;
    _selectedDays = List.from(widget.entry.daysOfWeek);
    _startTime = widget.entry.startTime;
    _endTime = widget.entry.endTime;
    _selectedReminderLead = widget.entry.reminders.isNotEmpty ? widget.entry.reminders.first : 15;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final currentStr = isStart ? _startTime : _endTime;
    final parts = currentStr.split(':');
    final initialHour = parts.length == 2 ? int.tryParse(parts[0]) ?? 8 : 8;
    final initialMinute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final timeFormatted = '$hourStr:$minuteStr';

      setState(() {
        if (isStart) {
          _startTime = timeFormatted;
        } else {
          _endTime = timeFormatted;
        }
      });
    }
  }

  void _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to remove "${widget.entry.title}" from this scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, {'deleted': true});
    }
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final updatedEntry = widget.entry.copyWith(
      title: title,
      category: _selectedCategory,
      daysOfWeek: _selectedDays,
      startTime: _startTime,
      endTime: _endTime,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      reminders: [_selectedReminderLead],
    );

    Navigator.pop(context, {'entry': updatedEntry});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Event',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Delete Event',
            onPressed: _onDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    _buildFieldLabel('Title', isDark),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. Programming 101',
                        prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Type / Category Selector
                    _buildFieldLabel('Type', isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ScheduleCategory>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: ScheduleCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(cat.icon, size: 18, color: cat.color),
                                  const SizedBox(width: 10),
                                  Text(cat.shortLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Day(s) Selection Pills
                    _buildFieldLabel('Day(s)', isDark),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekdays.map((item) {
                        final int day = item['day'];
                        final String name = item['name'];
                        final bool isSelected = _selectedDays.contains(day);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(day);
                              } else {
                                _selectedDays.add(day);
                                _selectedDays.sort();
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                                  : (isDark ? AppColors.surfaceDark : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_rounded, size: 14, color: Color(0xFF2563EB)),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Time Row (Start Time & End Time side-by-side)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Start Time', isDark),
                              GestureDetector(
                                onTap: () => _pickTime(isStart: true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Text(
                                        TimeUtils.formatTo12Hour(_startTime),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('End Time', isDark),
                              GestureDetector(
                                onTap: () => _pickTime(isStart: false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Text(
                                        TimeUtils.formatTo12Hour(_endTime),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Location
                    _buildFieldLabel('Location', isDark),
                    TextField(
                      controller: _locationController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: 'e.g. Room 204 or Online',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Reminder
                    _buildFieldLabel('Reminder', isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedReminderLead,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('At time of event')),
                            DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                            DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                            DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                            DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                            DropdownMenuItem(value: 60, child: Text('1 hour before')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedReminderLead = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Notes (Optional)
                    _buildFieldLabel('Notes (optional)', isDark),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add notes here...',
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom Save Changes Button
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
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
        ),
      ),
    );
  }
}
