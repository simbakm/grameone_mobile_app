import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/connectivity_utils.dart';
import '../../utils/whatsapp_utils.dart';
import '../screens/content_download_screen.dart';

/// Standard Empty Content State for subjects with no questions/topics yet.
/// Features:
/// 1. "Coming soon, no content yet available"
/// 2. "Check for Content Updates" (checks internet first; if offline displays connection required dialog)
/// 3. "Contact GrameOne Support on WhatsApp" with WhatsApp icon
class NoContentWidget extends StatelessWidget {
  final String subjectName;
  final String? customMessage;

  const NoContentWidget({
    super.key,
    required this.subjectName,
    this.customMessage,
  });

  Future<void> _handleCheckUpdates(BuildContext context) async {
    final hasInternet = await ConnectivityUtils.hasInternetConnection();

    if (!context.mounted) return;

    if (!hasInternet) {
      ConnectivityUtils.showOfflineDialog(context);
    } else {
      final provider = Provider.of<AppProvider>(context, listen: false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ContentDownloadScreen(
            gradeId: provider.currentGrade,
            gradeName: 'Grade ${provider.currentGrade}',
            isUpdateMode: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.lightGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.royalGold, width: 2),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  size: 36,
                  color: AppColors.royalGold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Coming soon, no content yet available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customMessage ??
                    'Content for $subjectName in Grade ${provider.currentGrade} is currently being prepared for distribution.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Button 1: Check for Content Updates (internet check first!)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleCheckUpdates(context),
                  icon: const Icon(Icons.system_update_alt, size: 20),
                  label: const Text('Check for Content Updates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Button 2: WhatsApp Support Link with WhatsApp Icon
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    WhatsAppUtils.openSupportWhatsApp(
                      context: context,
                      message:
                          'Hello GrameOne Support, I am inquiring about content availability for $subjectName in Grade ${provider.currentGrade}.',
                    );
                  },
                  icon: const WhatsAppIcon(size: 20),
                  label: const Text(
                    'Contact Support on WhatsApp',
                    style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    backgroundColor: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
