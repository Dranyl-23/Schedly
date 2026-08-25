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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Schedule Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Profile Name',
                      hintText: 'e.g. 2nd Semester Classes, Night Shift',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Profile Type'),
                    items: const [
                      DropdownMenuItem(value: 'school', child: Text('School / University')),
                      DropdownMenuItem(value: 'work', child: Text('Work / Job Shift')),
                      DropdownMenuItem(value: 'duty', child: Text('Duty Roster')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom / Personal')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final newProfile = ScheduleProfile(
                      name: name,
                      type: selectedType,
                      isActive: false,
                    );
                    await ref.read(profileListProvider.notifier).addProfile(newProfile);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Profile "$name" created!')),
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateProfileDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Schedule Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
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
