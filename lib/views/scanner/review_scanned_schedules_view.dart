import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';
import '../../providers/schedule_provider.dart';

class ReviewScannedSchedulesView extends ConsumerStatefulWidget {
  final List<ScheduleEntry> parsedEntries;

  const ReviewScannedSchedulesView({
    super.key,
    required this.parsedEntries,
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
    _entries = List.from(widget.parsedEntries);
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  void _editEntry(int index) async {
    final entry = _entries[index];
    final updated = await _showQuickEditDialog(entry);
    if (updated != null) {
      setState(() {
        _entries[index] = updated;
      });
    }
  }

  Future<ScheduleEntry?> _showQuickEditDialog(ScheduleEntry entry) async {
    final titleController = TextEditingController(text: entry.title);
    final locationController = TextEditingController(text: entry.location ?? '');
    ScheduleCategory category = entry.category;

    return showDialog<ScheduleEntry>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Extracted Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location / Room'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ScheduleCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ScheduleCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      entry.copyWith(
                        title: titleController.text.trim(),
                        location: locationController.text.trim().isNotEmpty
                            ? locationController.text.trim()
                            : null,
                        category: category,
                      ),
                    );
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveAll() async {
    if (_entries.isEmpty) {
      Navigator.pop(context);
      return;
    }

    await ref.read(scheduleListProvider.notifier).importBatch(_entries);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${_entries.length} schedules! 🚀'),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Extracted Schedule'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: ElevatedButton(
            onPressed: _entries.isEmpty ? null : _saveAll,
            child: Text(
              'Confirm & Save (${_entries.length} Entries)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: _entries.isEmpty
          ? const Center(
              child: Text(
                'No schedule entries extracted.\nPlease try another screenshot.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      // ignore: deprecated_member_use
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please verify the extracted days and times before saving to your calendar.',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final entryIndex = index - 1;
                final entry = _entries[entryIndex];
                final catColor = entry.category.color;
                final daysText = entry.daysOfWeek
                    .map((d) => TimeUtils.getWeekdayShort(d))
                    .join(', ');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: catColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.category.shortLabel,
                              style: TextStyle(
                                color: catColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editEntry(entryIndex),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            onPressed: () => _removeEntry(entryIndex),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            daysText,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            '${TimeUtils.formatTo12Hour(entry.startTime)} – ${TimeUtils.formatTo12Hour(entry.endTime)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (entry.location != null && entry.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(
                              entry.location!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
