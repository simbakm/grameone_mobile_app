import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';
import 'activation_screen.dart';
import 'grade_selection_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final grade = provider.settings?.selectedGrade ?? 7;
    final lang = provider.settings?.selectedIndigenousLang ?? 'Shona';
    final isActivated = provider.licenseInfo?.isActivated ?? false;
    final deviceId = provider.licenseInfo?.deviceId ?? 'DEV-GRAME-2026';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Grade Switcher
            Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: AppColors.emeraldGreen),
                title: const Text('Selected Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Current: Grade $grade'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Language Switcher
            Card(
              child: ListTile(
                leading: const Icon(Icons.translate, color: AppColors.royalGold),
                title: const Text('Indigenous Language', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Current: $lang'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // License Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isActivated ? Icons.verified : Icons.warning,
                          color: isActivated ? AppColors.correctGreen : AppColors.royalGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActivated ? 'License Activated' : 'Demo Mode (Unactivated)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isActivated ? AppColors.correctGreen : AppColors.royalGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Device ID: $deviceId', style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ActivationScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepMaroon,
                        ),
                        child: Text(isActivated ? 'RENEW LICENSE' : 'ACTIVATE FULL ACCESS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
