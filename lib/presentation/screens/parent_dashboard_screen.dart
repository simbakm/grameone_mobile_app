import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final unlockedBadges = provider.badges.where((b) => b.isUnlocked).toList();
    final recentAttempts = provider.recentAttempts;
    final weakConcepts = provider.weakConceptsDetailed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Parent Header Note
              Card(
                color: AppColors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.emeraldGreen),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.family_restroom, size: 40, color: AppColors.emeraldGreen),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Track your child\'s real learning progress, exam readiness, and revision consistency.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forestGreenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Progress Summary Grid (Real DB values)
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Overall Mastery',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${provider.overallScore.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepMaroon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Study Streak',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${provider.studyStreak} Days',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.royalGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Recommended Parent Guidance (Generated dynamically from real DB data)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended Parent Guidance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (weakConcepts.isEmpty)
                        const Text(
                          '• Encourage the learner to complete revision tests regularly to identify target areas.',
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
                        )
                      else
                        ...weakConcepts.take(3).map((w) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              '• Encourage practice on "${w.concept}" in ${w.subject} (current accuracy: ${w.accuracyPercentage.toStringAsFixed(0)}%).',
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Recent Test History (Real dynamic attempts from DB)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Test Attempts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (recentAttempts.isEmpty)
                        const Text(
                          'No tests completed yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        ...recentAttempts.map((attempt) {
                          final formattedDate = DateFormat('MMM d, y • HH:mm').format(attempt.timestamp);
                          final pct = attempt.scorePercentage;
                          final Color scoreColor = pct >= 80
                              ? AppColors.emeraldGreen
                              : pct >= 50
                                  ? AppColors.royalGold
                                  : AppColors.deepMaroon;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.bgLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.assignment, color: scoreColor),
                            ),
                            title: Text(
                              '${attempt.subject} (${attempt.testType})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '$formattedDate • ${attempt.correctCount}/${attempt.totalQuestions} Correct',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            trailing: Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: scoreColor,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Badges Earned Summary (Real dynamic data)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earned Badges & Achievements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (unlockedBadges.isEmpty)
                        const Text(
                          'No badges earned yet. Complete quizzes to unlock achievements!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        ...unlockedBadges.map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.workspace_premium, color: AppColors.badgeUnlocked, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        b.description,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
}
