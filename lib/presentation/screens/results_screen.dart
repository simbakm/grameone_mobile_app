import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/quiz_engine.dart';
import '../../data/models/models.dart';
import '../../theme/app_theme.dart';
import 'home_dashboard_screen.dart';
import 'quiz_screen.dart';
import 'review_screen.dart';
import 'units_screen.dart';

class ResultsScreen extends StatelessWidget {
  final QuizAttempt attempt;

  const ResultsScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final double pct = attempt.scorePercentage;
    final int stars = pct >= 80 ? 3 : pct >= 50 ? 2 : 1;
    final totalAvailable = provider.totalUnitQuestionsAvailable;
    final bool isUnitPractice = attempt.testType == 'Practice';
    final bool hasMoreQuestions = totalAvailable > 20;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUnitPractice ? 'Unit Exercise Results' : 'Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stars display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Icon(
                    index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 56,
                    color: AppColors.royalGold,
                  );
                }),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You scored ${attempt.correctCount} out of ${attempt.totalQuestions}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Chip(
                        label: Text(
                          pct >= 80
                              ? 'Outstanding Performance!'
                              : pct >= 50
                                  ? 'Good Job! Keep Practicing'
                                  : 'Needs Revision',
                          style: const TextStyle(
                            color: AppColors.surfaceLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: pct >= 80
                            ? AppColors.emeraldGreen
                            : pct >= 50
                                ? AppColors.royalGold
                                : AppColors.deepMaroon,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Unit Exercises Specific Action Buttons ──
              if (isUnitPractice) ...[
                // Take More Unit Exercises Button
                ElevatedButton.icon(
                  onPressed: hasMoreQuestions
                      ? () async {
                          await provider.startQuiz(
                            testType: TestType.practice,
                            subject: attempt.subject,
                            topic: attempt.topic,
                            unit: provider.currentQuizUnit,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const QuizScreen()),
                          );
                        }
                      : null, // Disabled when all unit questions completed
                  icon: Icon(hasMoreQuestions ? Icons.play_circle_fill : Icons.check_circle),
                  label: Text(
                    hasMoreQuestions
                        ? 'TAKE MORE UNIT EXERCISES'
                        : 'ALL UNIT QUESTIONS COMPLETED',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasMoreQuestions ? AppColors.emeraldGreen : AppColors.borderLight,
                    foregroundColor: hasMoreQuestions ? Colors.white : AppColors.textSecondaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // Return to Units Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => UnitsScreen(
                          subject: attempt.subject,
                          topic: attempt.topic,
                        ),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('RETURN TO UNITS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepMaroon,
                    side: const BorderSide(color: AppColors.deepMaroon, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Standard Review Answers Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewScreen(attemptId: attempt.id),
                    ),
                  );
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('REVIEW ANSWERS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalGold,
                  foregroundColor: AppColors.textPrimaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Standard Return to Dashboard Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeDashboardScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('RETURN TO DASHBOARD'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
