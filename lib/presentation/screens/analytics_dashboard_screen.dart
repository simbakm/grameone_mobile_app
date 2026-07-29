import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final selectedLang = provider.settings?.selectedIndigenousLang ?? 'Shona';
    final subjects = [
      'Science',
      'Mathematics',
      'English',
      'Agriculture',
      'Social Science',
      'Indigenous Language',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learner Analytics'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Study Streak & Overview Banner
              Card(
                color: AppColors.lightGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.royalGold, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.royalGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: AppColors.surfaceLight,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${provider.studyStreak} Day Study Streak!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Overall Average Score: ${provider.overallScore.toStringAsFixed(0)}% • ${provider.testsDone} Tests Completed',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subject Mastery Section (Dynamic real data from DB)
              const Text(
                'Subject Mastery Levels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepMaroon,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: subjects.map((sub) {
                      final displayName = sub == 'Indigenous Language'
                          ? 'Indigenous Language ($selectedLang)'
                          : sub;
                      final double score = provider.subjectPerformance[sub] ?? 0.0;
                      final double fraction = (score / 100.0).clamp(0.0, 1.0);
                      final Color barColor = score >= 80
                          ? AppColors.emeraldGreen
                          : score >= 50
                              ? AppColors.royalGold
                              : AppColors.deepMaroon;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildMasteryBar(displayName, fraction, score, barColor),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Weak Concepts Focus Area (Dynamic real data from DB)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: AppColors.deepMaroon),
                          SizedBox(width: 8),
                          Text(
                            'Concepts Needing Attention',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepMaroon,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.weakConceptsDetailed.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No weak concepts identified yet. Complete tests to generate concept analytics!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...provider.weakConceptsDetailed.map((concept) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.arrow_right, color: AppColors.deepMaroon),
                            title: Text(
                              '${concept.concept} (${concept.subject})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Accuracy: ${concept.accuracyPercentage.toStringAsFixed(0)}% • ${concept.correctCount}/${concept.totalCount} correct',
                              style: const TextStyle(color: AppColors.textSecondaryLight),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Strong Concepts Area (Dynamic real data from DB)
              if (provider.strongConceptsDetailed.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle_outline, color: AppColors.emeraldGreen),
                            SizedBox(width: 8),
                            Text(
                              'Strong Mastery Concepts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...provider.strongConceptsDetailed.map((concept) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.star, color: AppColors.royalGold),
                            title: Text(
                              '${concept.concept} (${concept.subject})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Accuracy: ${concept.accuracyPercentage.toStringAsFixed(0)}% • ${concept.correctCount}/${concept.totalCount} correct',
                              style: const TextStyle(color: AppColors.textSecondaryLight),
                            ),
                          );
                        }),
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

  Widget _buildMasteryBar(String subject, double fraction, double score, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              score > 0 ? '${score.toStringAsFixed(0)}%' : 'Not attempted',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: score > 0 ? barColor : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
