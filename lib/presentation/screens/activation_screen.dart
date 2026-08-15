import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/api_service.dart';
import '../../application/app_provider.dart';
import '../../data/models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/whatsapp_utils.dart';
import 'grade_selection_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  Future<void> _handleActivation() async {
    final rawInput = _codeController.text.trim().toUpperCase();
    if (rawInput.isEmpty) {
      setState(() => _errorMessage = 'Please enter an activation code.');
      return;
    }

    final codes = rawInput.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    final deviceId = provider.licenseInfo?.deviceId ?? 'UNKNOWN';

    Map<String, dynamic> result;
    if (codes.length > 1) {
      result = await ApiService.validateMultiLicenses(codes, deviceId, gradeId: provider.currentGrade);
    } else {
      result = await ApiService.validateLicense(codes.first, deviceId, gradeId: provider.currentGrade);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['valid'] == true) {
      // Persist the activation locally
      await provider.activateLicenseFromApi(
        code: rawInput,
        expiryDate: result['expiryDate'],
        gradeIds: result['gradeIds'],
        licenseType: result['licenseType'] ?? (codes.length > 1 ? 'MULTI_GRADE' : 'STANDARD'),
      );

      setState(() => _successMessage = result['message'] ?? 'Activation successful!');
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
      );
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Invalid activation code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final deviceId = provider.licenseInfo?.deviceId ?? '...';

    return Scaffold(
      appBar: AppBar(title: const Text('Device Activation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // ── Hero card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightGreen, AppColors.emeraldGreen.withAlpha(30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.emeraldGreen, width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.shield_outlined, size: 52, color: AppColors.emeraldGreen),
                  const SizedBox(height: 12),
                  Text(
                    'Activating for: ${provider.activeLearner?.name ?? 'Learner'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepMaroon,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'License will be linked to ${provider.activeLearner?.name ?? 'this learner'} (Grade ${provider.currentGrade}).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
                  ),
                  if (provider.learnerProfiles.length > 1) ...[
                    const SizedBox(height: 10),
                    PopupMenuButton<LearnerProfile>(
                      onSelected: (profile) => provider.switchLearnerProfile(profile),
                      itemBuilder: (context) => provider.learnerProfiles.map((p) => PopupMenuItem(
                        value: p,
                        child: Text('${p.avatar} ${p.name} (Grade ${p.grade})'),
                      )).toList(),
                      child: Chip(
                        avatar: Text(provider.activeLearner?.avatar ?? '🧒'),
                        label: Text('Change Learner: ${provider.activeLearner?.name} ▾'),
                        backgroundColor: AppColors.royalGold.withAlpha(40),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: SelectableText(
                      deviceId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimaryLight,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'An activation code can be obtained from your school or by contacting GrameOne support on WhatsApp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Activation input ───────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Activation Code',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'e.g. GRAME-XXXX-XXXX',
                        prefixIcon: const Icon(Icons.vpn_key, color: AppColors.royalGold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.emeraldGreen, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _isLoading ? null : _handleActivation(),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.incorrectRed),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.incorrectRed, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_successMessage != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.emeraldGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleActivation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'ACTIVATE APPLICATION',
                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── WhatsApp support button ────────────────────────────────────
            Card(
              color: const Color(0xFFDCFCE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              ),
              child: ListTile(
                leading: const WhatsAppIcon(size: 28),
                title: const Text(
                  'Need Help with Activation?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight, fontSize: 14),
                ),
                subtitle: const Text(
                  'If you need help with activation, tap to contact GrameOne support.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                trailing: const Icon(Icons.open_in_new, color: Color(0xFF16A34A)),
                onTap: () {
                  WhatsAppUtils.openSupportWhatsApp(
                    context: context,
                    message: 'Hello GrameOne Support, I need help with activating my application.',
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
