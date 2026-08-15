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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
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
      backgroundColor: const Color(0xFF034A2C),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_screen.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.deepMaroon,
                child: const Center(
                  child: Text(
                    'GrameOne',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 48,
            right: 48,
            bottom: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.black26,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalGold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Loading GrameOne...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
