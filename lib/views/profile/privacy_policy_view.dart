import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 28, color: Color(0xFF2563EB)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Privacy Comes First',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Last updated: August 2026',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: '1. Overview',
                content:
                    'Schedly is committed to protecting your privacy. We believe your daily schedule, university coursework, hospital duties, and work shifts are personal. This Privacy Policy explains how our application processes, stores, and protects your information.',
                isDark: isDark,
              ),

              _buildSection(
                title: '2. Information We Collect',
                content:
                    '• Profile Information: Your name, email address, and profile photo when signing in with Google or creating an account.\n'
                    '• Schedule Data: Subject titles, shift timings, days of the week, classroom or workplace locations, and instructor/supervisor notes.\n'
                    '• Device Preferences: Notification settings, alarm lead times, and theme mode choices.',
                isDark: isDark,
              ),

              _buildSection(
                title: '3. On-Device AI, OCR Privacy & Dataset Improvement',
                content:
                    '• Offline Mode: Images and PDF documents scanned in Offline Mode are processed 100% locally on your device using Google ML Kit Vision. No images are uploaded to any third-party advertising network.\n'
                    '• Online Mode: When utilizing cloud AI enhancement, images are transmitted over encrypted TLS connections strictly for timetable parsing and are not retained for marketing purposes.\n'
                    '• Anonymous AI Dataset Contribution: Users can optionally help improve the offline scanner AI accuracy by anonymously contributing schedule formatting structures. Personal IDs, student identification numbers, and sensitive details are never collected or stored, and users can disable this anytime in AI Settings.',
                isDark: isDark,
              ),

              _buildSection(
                title: '4. Cloud Storage & Security',
                content:
                    'When logged in, your schedule data is safely synchronized with your private Google Firebase Firestore cloud database, protected by granular security rules allowing only your authenticated account to read or write your timetable.',
                isDark: isDark,
              ),

              _buildSection(
                title: '5. Data Control & Export Rights',
                content:
                    'You retain full ownership of your data at all times. You can:\n'
                    '• Export your complete schedule as formatted text, Excel CSV, or raw JSON backup directly from the Profile screen.\n'
                    '• Permanently delete individual schedules or your entire account and all associated cloud data with one tap.',
                isDark: isDark,
              ),

              _buildSection(
                title: '6. Contact & Support',
                content:
                    'If you have any questions or feedback regarding this Privacy Policy, feel free to contact the development team through the in-app support channels.',
                isDark: isDark,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
