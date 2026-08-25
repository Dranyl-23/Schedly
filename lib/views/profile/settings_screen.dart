import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../settings/battery_optimization_view.dart';
import 'about_schedly_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsGroup(
            isDark: isDark,
            items: [
              _buildSettingTile(
                icon: Icons.tune_rounded,
                title: 'General',
                subtitle: 'App preferences & time format',
                isDark: isDark,
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Manage background reminder alarms',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BatteryOptimizationView(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.cloud_sync_outlined,
                title: 'Backup & Sync',
                subtitle: 'Sync your schedules to cloud',
                isDark: isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cloud sync enabled! ☁️')),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                isDark: isDark,
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English (US)',
                isDark: isDark,
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About Schedly',
                subtitle: 'Version 1.0.0',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutSchedlyView()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required List<Widget> items,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
