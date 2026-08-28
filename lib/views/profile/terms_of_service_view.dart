import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
                    Icon(Icons.description_outlined, size: 28, color: Color(0xFF2563EB)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Conditions',
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
                title: '1. Acceptance of Terms',
                content:
                    'By downloading, installing, or using Schedly, you agree to be bound by these Terms of Service. If you do not agree to these terms, please discontinue using the application.',
                isDark: isDark,
              ),

              _buildSection(
                title: '2. Purpose of the Application',
                content:
                    'Schedly is designed as a personal schedule management and productivity assistant for university students, healthcare professionals, corporate employees, shift crew, and general users to organize classes, duties, and routines with intelligent alarms and timetable grids.',
                isDark: isDark,
              ),

              _buildSection(
                title: '3. AI Schedule Extraction & Review Responsibility',
                content:
                    '• Automated Tool: The optical character recognition (OCR) and AI schedule parsing features are provided to accelerate schedule entry.\n'
                    '• User Review: AI extraction accuracy depends on document resolution, lighting, and layout complexity. Users are advised to review and verify extracted class names, times, and venues on the Review & Edit screen before final saving.',
                isDark: isDark,
              ),

              _buildSection(
                title: '4. Notifications & Exact Alarms',
                content:
                    'Schedly utilizes Android exact alarms to deliver timely event reminders. Users are responsible for granting necessary system alarm permissions and battery optimization exceptions to ensure background reminder delivery.',
                isDark: isDark,
              ),

              _buildSection(
                title: '5. Account Security',
                content:
                    'If you choose to sign in with Google or cloud authentication, you are responsible for maintaining the security of your device and credentials.',
                isDark: isDark,
              ),

              _buildSection(
                title: '6. Modifications to the Service',
                content:
                    'We continuously improve Schedly and may update, enhance, or adjust features to deliver better performance and user experience.',
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
