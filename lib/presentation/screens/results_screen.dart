import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../theme/app_theme.dart';
import 'home_dashboard_screen.dart';
import 'review_screen.dart';

class ResultsScreen extends StatelessWidget {
  final QuizAttempt attempt;

  const ResultsScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final double pct = attempt.scorePercentage;
    final int stars = pct >= 80 ? 3 : pct >= 50 ? 2 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
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
              const SizedBox(height: 32),
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
                ),
              ),
              const SizedBox(height: 12),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
