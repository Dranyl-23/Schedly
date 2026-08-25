import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle breathing/floating idle animation for the 3D logo
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _startTransitionTimer();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _startTransitionTimer() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    _navigateToNext();
  }

  void _navigateToNext() {
    final auth = ref.read(authProvider);
    final targetScreen =
        auth.isLoggedIn ? const MainNavigationShell() : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      SmoothSlideFadeRoute(page: targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToNext,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0038FF), // Royal Schedly Blue
                Color(0xFF1E1B4B), // Deep Navy
                Color(0xFF4C1D95), // Rich Purple Accent
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient Glowing Center Light
              Positioned(
                top: screenSize.height * 0.22,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
                        blurRadius: 120,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Prominent 3D Schedly Logo with Float & Scale Entrance
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: screenSize.height * 0.34,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.calendar_month_rounded,
                            size: 100,
                            color: Colors.white,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 650.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 800.ms,
                              curve: Curves.easeOutBack,
                            )
                            .shimmer(
                              delay: 850.ms,
                              duration: 1200.ms,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                      ),

                      const SizedBox(height: 40),

                      // Tagline: "Scan. Parse. Schedule."
                      const Text(
                        'Scan. Parse. Schedule.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 550.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: 6),

                      // Tagline: "Get Reminded." (Cyan Gradient Accent)
                      const Text(
                        'Get Reminded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                          letterSpacing: -0.6,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 550.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: 16),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Turn any schedule screenshot\ninto reminders you\'ll never miss.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.45,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 550.ms)
                          .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
