import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/widgets/google_logo.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_shell.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  void _completeAuth(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).login();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        SmoothSlideFadeRoute(page: const MainNavigationShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // 3D Schedly Logo Image with Entrance Scale Animation
              Image.asset(
                'assets/images/logo.png',
                height: 210,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.calendar_month_rounded,
                  size: 90,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 20),

              // Welcome Heading
              Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Please log in to continue\nmanaging your schedules.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  height: 1.4,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 32),

              // Continue with Google Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () => _completeAuth(context, ref),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 450.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 14),

              // Continue with Email Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () => _completeAuth(context, ref),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 450.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              // Divider with 'or'
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 24),

              // Create Account Button (Primary Gradient)
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _completeAuth(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 650.ms, duration: 450.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 28),

              // Already have an account? Log in
              GestureDetector(
                onTap: () => _completeAuth(context, ref),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                    children: const [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Log in',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 750.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
