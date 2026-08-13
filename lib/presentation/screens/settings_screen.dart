import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/api_service.dart';
import '../../application/app_provider.dart';
import '../../data/models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/whatsapp_utils.dart';
import 'activation_screen.dart';
import 'content_download_screen.dart';
import 'grade_selection_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _alphabet = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  void _showAddLearnerDialog(BuildContext context, AppProvider provider) {
    int selectedGrade = 7;
    String selectedLang = 'Shona';
    final codeController = TextEditingController();
    String? dialogError;
    bool isSaving = false;

    final existingCount = provider.learnerProfiles.length;
    final letter = existingCount < _alphabet.length ? _alphabet[existingCount] : '${existingCount + 1}';
    final defaultName = 'Learner $letter';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.person_add_alt_1_outlined, color: AppColors.emeraldGreen),
                SizedBox(width: 8),
                Text('Add Learner Profile'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Title: $defaultName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryLight),
                ),
                const SizedBox(height: 4),
                const Text(
                  'We do not collect any personal data or names.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Grade: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: selectedGrade,
                      items: [1, 2, 3, 4, 5, 6, 7].map((g) => DropdownMenuItem(value: g, child: Text('Grade $g'))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedGrade = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Language: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedLang,
                      items: ['Shona', 'Ndebele'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedLang = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Activation Code required for 2nd+ learner
                if (existingCount >= 1) ...[
                  const Text(
                    'Learner Activation Code *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.deepMaroon),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter activation code for $defaultName',
                      prefixIcon: const Icon(Icons.vpn_key, color: AppColors.royalGold),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'An additional activation code is required for each extra learner profile.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],

                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError!,
                    style: const TextStyle(color: AppColors.incorrectRed, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final code = codeController.text.trim().toUpperCase();

                        // For 2nd+ learner, validate activation code
                        if (existingCount >= 1) {
                          if (code.isEmpty) {
                            setState(() => dialogError = 'Please enter an activation code for $defaultName.');
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          final devId = provider.licenseInfo?.deviceId ?? 'UNKNOWN';
                          final result = await ApiService.validateLicense(code, devId);

                          if (result['valid'] != true) {
                            setState(() {
                              isSaving = false;
                              dialogError = result['message'] ?? 'Invalid activation code for $defaultName.';
                            });
                            return;
                          }
                        }

                        final newProfile = LearnerProfile(
                          id: 'learner_${DateTime.now().millisecondsSinceEpoch}',
                          name: defaultName,
                          avatar: '🧒',
                          grade: selectedGrade,
                          indigenousLanguage: selectedLang,
                          createdAt: DateTime.now(),
                        );

                        await provider.createOrUpdateLearnerProfile(newProfile);
                        if (context.mounted) Navigator.of(ctx).pop();
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('ADD LEARNER'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLicenseExpirySection(BuildContext context, AppProvider provider) {
    final license = provider.licenseInfo;
    final isActivated = license?.isActivated ?? false;
    final deviceId = license?.deviceId ?? 'DEV-GRAME-2026';

    String expiryText = 'No active license found';
    String daysText = '';
    Color statusColor = AppColors.royalGold;

    if (isActivated && license?.expiryDate != null) {
      final now = DateTime.now();
      final remaining = license!.expiryDate!.difference(now);
      final days = remaining.inDays;
      final hours = remaining.inHours;

      if (remaining.isNegative) {
        statusColor = AppColors.incorrectRed;
        expiryText = 'License Expired';
        daysText = 'Expired on ${license.expiryDate!.day}/${license.expiryDate!.month}/${license.expiryDate!.year}';
      } else if (days <= 1) {
        statusColor = AppColors.incorrectRed;
        expiryText = 'License Expiring Soon';
        daysText = '$hours hours remaining';
      } else {
        statusColor = AppColors.emeraldGreen;
        expiryText = 'License Active';
        daysText = '$days days remaining (expires ${license.expiryDate!.day}/${license.expiryDate!.month}/${license.expiryDate!.year})';
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActivated ? Icons.verified_user_outlined : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActivated ? expiryText : 'Demo Mode (Unactivated)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor,
                        ),
                      ),
                      if (daysText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          daysText,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.phone_android, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text('Device ID: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    deviceId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isActivated ? 'RENEW LICENSE' : 'ACTIVATE FULL ACCESS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final activeLearner = provider.activeLearner;
    final isGradeLocked = provider.isGradeLocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ── Learner Profiles Section ──
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.people, color: AppColors.emeraldGreen),
                            SizedBox(width: 8),
                            Text('Registered Learners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddLearnerDialog(context, provider),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Learner'),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    ...provider.learnerProfiles.map((profile) {
                      final isSelected = activeLearner?.id == profile.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.lightGreen : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.emeraldGreen : AppColors.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Text(profile.avatar, style: const TextStyle(fontSize: 24)),
                          title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Grade ${profile.grade} • ${profile.indigenousLanguage}'),
                          trailing: isSelected
                              ? const Chip(
                                  label: Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppColors.emeraldGreen,
                                )
                              : OutlinedButton(
                                  onPressed: () => provider.switchLearnerProfile(profile),
                                  child: const Text('Switch'),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Grade Switcher (Locked after download)
            Card(
              child: ListTile(
                leading: Icon(
                  isGradeLocked ? Icons.lock : Icons.school,
                  color: isGradeLocked ? AppColors.textSecondaryLight : AppColors.emeraldGreen,
                ),
                title: Text(
                  'Active Grade${isGradeLocked ? " (Locked)" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isGradeLocked
                      ? 'Grade ${provider.currentGrade} • Locked under downloaded license'
                      : 'Current: Grade ${provider.currentGrade}',
                ),
                trailing: Icon(
                  isGradeLocked ? Icons.lock : Icons.chevron_right,
                  color: isGradeLocked ? AppColors.textSecondaryLight : AppColors.emeraldGreen,
                ),
                onTap: isGradeLocked
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Grade selection is locked to Grade ${provider.currentGrade}.'),
                          ),
                        );
                      }
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
                        );
                      },
              ),
            ),
            const SizedBox(height: 8),

            // Language Switcher (Always accessible)
            Card(
              child: ListTile(
                leading: const Icon(Icons.translate, color: AppColors.royalGold),
                title: const Text('Indigenous Language', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Current: ${provider.currentIndigenousLang}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Check for Content Updates (Question Bank Sync)
            Card(
              child: ListTile(
                leading: const Icon(Icons.system_update_alt, color: AppColors.emeraldGreen),
                title: const Text('Check for Content Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Sync & download latest Grade ${provider.currentGrade} question bank'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.emeraldGreen),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContentDownloadScreen(
                        gradeId: provider.currentGrade,
                        gradeName: 'Grade ${provider.currentGrade}',
                        isUpdateMode: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // WhatsApp Support Link Button (Requirement 8)
            Card(
              color: const Color(0xFFDCFCE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              ),
              child: ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF16A34A), size: 28),
                title: const Text(
                  'Need Assistance? Contact Support',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                ),
                subtitle: const Text(
                  'Chat with GrameOne support on WhatsApp',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                trailing: const Icon(Icons.open_in_new, color: Color(0xFF16A34A)),
                onTap: () => WhatsAppUtils.openSupportWhatsApp(context: context),
              ),
            ),
            const SizedBox(height: 16),

            // License Information & Expiration Card
            _buildLicenseExpirySection(context, provider),
          ],
        ),
      ),
    );
  }
}
