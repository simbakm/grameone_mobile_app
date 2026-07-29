import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';

class ReviewScreen extends StatelessWidget {
  final String attemptId;

  const ReviewScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final questions = provider.currentQuizQuestions;
    final answers = provider.currentAttemptAnswers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            final answer = index < answers.length ? answers[index] : null;
            final isCorrect = answer?.isCorrect ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isCorrect ? AppColors.correctGreen : AppColors.incorrectRed,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isCorrect ? AppColors.lightGreen : AppColors.lightMaroon,
                          radius: 16,
                          child: Icon(
                            isCorrect ? Icons.check : Icons.close,
                            color: isCorrect ? AppColors.correctGreen : AppColors.incorrectRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Question ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    ...question.options.map((opt) {
                      final isSelected = answer?.selectedOptionId == opt.id;
                      Color itemColor = AppColors.textPrimaryLight;
                      if (opt.isCorrect) {
                        itemColor = AppColors.correctGreen;
                      } else if (isSelected && !opt.isCorrect) {
                        itemColor = AppColors.incorrectRed;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              opt.isCorrect
                                  ? Icons.check_circle
                                  : isSelected
                                      ? Icons.cancel
                                      : Icons.radio_button_unchecked,
                              color: itemColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                opt.optionText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: opt.isCorrect || isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: itemColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Concept: ${question.concept}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepMaroon,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            question.explanation,
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
            );
          },
        ),
      ),
    );
  }
}
