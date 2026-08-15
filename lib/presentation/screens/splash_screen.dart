import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';
import 'activation_screen.dart';
import 'grade_selection_screen.dart';
import 'home_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.initializeApp();

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final license = appProvider.licenseInfo;
    if (license == null || !license.isActivated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActivationScreen()),
      );
    } else if (appProvider.settings == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepMaroon,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Small centered app icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.school,
                      size: 80,
                      color: AppColors.royalGold,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App name
                const Text(
                  'GrameOne',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Made in Zimbabwe badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.royalGold.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.royalGold.withAlpha(100), width: 1),
                  ),
                  child: const Text(
                    '🇿🇼  Made in Zimbabwe',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.royalGold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Curriculum line
                const Text(
                  'Grade 7 ZIMSEC Curriculum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 52),

                // Loading indicator
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalGold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
