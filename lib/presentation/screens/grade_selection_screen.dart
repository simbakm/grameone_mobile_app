import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';
import 'content_download_screen.dart';

class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key});

  Future<void> _confirmAndStartDownload(
    BuildContext context,
    AppProvider provider,
    int gradeNum,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.download_for_offline_outlined, color: AppColors.emeraldGreen),
            SizedBox(width: 8),
            Text('Confirm Grade'),
          ],
        ),
        content: Text(
          'Are you sure you want to download content for Grade $gradeNum?\n\n'
          'Once downloaded, your grade selection will be locked for this license.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
            child: const Text('CONFIRM & DOWNLOAD'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await provider.setGrade(gradeNum);

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContentDownloadScreen(
          gradeId: gradeNum,
          gradeName: 'Grade $gradeNum',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isLocked = provider.isGradeLocked;
    final currentGrade = provider.currentGrade;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Grade')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome ${provider.activeLearner?.name ?? 'Learner'}! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepMaroon,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isLocked
                    ? '${provider.activeLearner?.name ?? 'This profile'} is locked to Grade $currentGrade. You can change your Indigenous Language in Settings anytime.'
                    : 'Choose grade for ${provider.activeLearner?.name ?? 'this profile'}. We\'ll download the latest question pack automatically.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.4),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final int gradeNum = index + 1;
                    final bool isCurrent = gradeNum == currentGrade;
                    final bool isCardDisabled = isLocked && !isCurrent;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isCurrent ? AppColors.royalGold : AppColors.borderLight,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      color: isCardDisabled ? AppColors.bgLight : AppColors.surfaceLight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: isCardDisabled
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Grade selection is locked to Grade $currentGrade.'),
                                  ),
                                );
                              }
                            : () => _confirmAndStartDownload(context, provider, gradeNum),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isCardDisabled
                                      ? AppColors.borderLight
                                      : (isCurrent ? AppColors.emeraldGreen : AppColors.lightGreen),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$gradeNum',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isCardDisabled
                                          ? AppColors.textSecondaryLight
                                          : (isCurrent ? Colors.white : AppColors.emeraldGreen),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Grade $gradeNum',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isCardDisabled
                                                ? AppColors.textSecondaryLight
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        if (isLocked && isCurrent) ...[
                                          const SizedBox(width: 8),
                                          const Chip(
                                            label: Text('Locked Grade', style: TextStyle(fontSize: 10, color: Colors.white)),
                                            backgroundColor: AppColors.deepMaroon,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isCardDisabled
                                        ? 'Locked under current license'
                                        : (gradeNum == 7
                                            ? 'Grade 7 ZIMSEC Exam Prep – Tap to download'
                                            : 'Primary Revision Pack – Tap to download'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isCardDisabled ? Icons.lock : Icons.download,
                                color: isCardDisabled ? AppColors.textSecondaryLight : AppColors.emeraldGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
