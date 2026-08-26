import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/schedule_profile.dart';
import '../../providers/profile_provider.dart';

class ScheduleProfilesView extends ConsumerWidget {
  const ScheduleProfilesView({super.key});

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'school';
    String selectedHex = '#2563EB';

    final typeOptions = [
      {
        'type': 'school',
        'title': 'School / University',
        'desc': 'Class timetables, lectures & lab sessions',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF2563EB),
        'hex': '#2563EB',
      },
      {
        'type': 'work',
        'title': 'Work / Job Shift',
        'desc': 'Office hours, part-time shifts & meetings',
        'icon': Icons.work_rounded,
        'color': const Color(0xFFF59E0B),
        'hex': '#F59E0B',
      },
      {
        'type': 'duty',
        'title': 'Duty Roster',
        'desc': 'Hospital shifts, clinical duties & rotations',
        'icon': Icons.badge_rounded,
        'color': const Color(0xFF10B981),
        'hex': '#10B981',
      },
      {
        'type': 'custom',
        'title': 'Custom / Personal',
        'desc': 'Fitness, study routines & personal habits',
        'icon': Icons.star_rounded,
        'color': const Color(0xFF8B5CF6),
        'hex': '#8B5CF6',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                ),
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 42,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New Schedule Profile',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Create a separate timetable for school, duty, or work',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Profile Name Field
                        Text(
                          'PROFILE NAME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: nameController,
                            autofocus: false,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 2nd Semester Classes, Hospital Duty',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.bookmark_outline_rounded,
                                size: 20,
                                color: Color(0xFF2563EB),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Profile Type Selection
                        Text(
                          'SELECT PROFILE CATEGORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 4 Option Cards
                        ...typeOptions.map((opt) {
                          final typeKey = opt['type'] as String;
                          final isSelected = selectedType == typeKey;
                          final optColor = opt['color'] as Color;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  selectedType = typeKey;
                                  selectedHex = opt['hex'] as String;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? optColor.withValues(alpha: 0.09)
                                      : (isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? optColor
                                        : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.6 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: optColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        opt['icon'] as IconData,
                                        color: optColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            opt['title'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isSelected
                                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            opt['desc'] as String,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: isSelected ? optColor : const Color(0xFFCBD5E1),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 18),

                        // Create Button
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a profile name'),
                                    backgroundColor: Color(0xFFDC2626),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final newProfile = ScheduleProfile(
                                name: name,
                                type: selectedType,
                                colorHex: selectedHex,
                                isActive: false,
                              );
                              await ref.read(profileListProvider.notifier).addProfile(newProfile);
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Profile "$name" created successfully! 🎉'),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Create Profile',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profiles = ref.watch(profileListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Schedule Profile',
            onPressed: () => _showCreateProfileDialog(context, ref),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: profiles.length + 1, // +1 for the Add New Profile button at the end
        itemBuilder: (context, index) {
          if (index == profiles.length) {
            // End Action Card: Add New Profile
            return Container(
              margin: const EdgeInsets.only(top: 8),
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showCreateProfileDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'New Schedule Profile',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            );
          }

          final profile = profiles[index];
          final isSelected = profile.isActive;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: profile.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(profile.icon, color: profile.color, size: 22),
              ),
              title: Text(
                profile.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              subtitle: Text(
                isSelected
                    ? 'Active • Updated ${DateFormat('MMM d, yyyy').format(profile.updatedAt)}'
                    : 'Updated ${DateFormat('MMM d, yyyy').format(profile.updatedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: Radio<bool>(
                value: true,
                // ignore: deprecated_member_use
                groupValue: isSelected,
                activeColor: const Color(0xFF2563EB),
                // ignore: deprecated_member_use
                onChanged: (_) {
                  ref.read(profileListProvider.notifier).setActive(profile.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Switched to "${profile.name}"')),
                  );
                },
              ),
              onTap: () {
                ref.read(profileListProvider.notifier).setActive(profile.id);
              },
            ),
          );
        },
      ),
    );
  }
}
