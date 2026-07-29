import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/quiz_engine.dart';
import '../../data/models/models.dart';
import '../../theme/app_theme.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? _selectedOptionId;
  bool _hasAnswered = false;
  bool _isCorrect = false;

  void _onSelectOption(QuestionOption option) {
    if (_hasAnswered) return;
    setState(() {
      _selectedOptionId = option.id;
      _hasAnswered = true;
      _isCorrect = option.isCorrect;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.answerCurrentQuestion(option.id, option.isCorrect);
  }

  void _onNextPressed() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final questions = provider.currentQuizQuestions;
    final currentIndex = provider.currentQuestionIndex;

    if (currentIndex < questions.length - 1) {
      setState(() {
        _selectedOptionId = null;
        _hasAnswered = false;
        _isCorrect = false;
      });
      provider.nextQuestion();
    } else {
      // Quiz completed!
      final currentQuestion = questions.first;
      final attempt = await provider.finishQuiz(
        TestType.practice,
        currentQuestion.subject,
        currentQuestion.topic,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(attempt: attempt),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final questions = provider.currentQuizQuestions;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_dissatisfied, size: 64, color: AppColors.royalGold),
              const SizedBox(height: 16),
              const Text('No questions available for this selection.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('GO BACK'),
              ),
            ],
          ),
        ),
      );
    }

    final currentIndex = provider.currentQuestionIndex;
    final currentQuestion = questions[currentIndex];
    final double progress = (currentIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${currentQuestion.subject} - Q${currentIndex + 1}/${questions.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
              minHeight: 6,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Meta Concept Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.bookmark_outline, size: 16, color: AppColors.deepMaroon),
                          label: Text(
                            currentQuestion.topic,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppColors.lightGold,
                        ),
                        Chip(
                          label: Text(
                            currentQuestion.difficulty,
                            style: const TextStyle(fontSize: 12, color: AppColors.surfaceLight),
                          ),
                          backgroundColor: currentQuestion.difficulty.toLowerCase() == 'hard'
                              ? AppColors.deepMaroon
                              : AppColors.emeraldGreen,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Question Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          currentQuestion.questionText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Options List
                    ...currentQuestion.options.map((option) {
                      bool isSelected = _selectedOptionId == option.id;
                      Color borderColor = AppColors.borderLight;
                      Color bgColor = AppColors.surfaceLight;

                      if (_hasAnswered) {
                        if (option.isCorrect) {
                          borderColor = AppColors.correctGreen;
                          bgColor = AppColors.lightGreen;
                        } else if (isSelected && !option.isCorrect) {
                          borderColor = AppColors.incorrectRed;
                          bgColor = AppColors.lightMaroon;
                        }
                      } else if (isSelected) {
                        borderColor = AppColors.emeraldGreen;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor, width: 2),
                          ),
                          color: bgColor,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _onSelectOption(option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: borderColor, width: 2),
                                    ),
                                    child: Center(
                                      child: _hasAnswered && option.isCorrect
                                          ? const Icon(Icons.check, size: 20, color: AppColors.correctGreen)
                                          : _hasAnswered && isSelected && !option.isCorrect
                                              ? const Icon(Icons.close, size: 20, color: AppColors.incorrectRed)
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.optionText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Feedback Card
                    if (_hasAnswered) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect ? AppColors.lightGreen : AppColors.lightMaroon,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect ? AppColors.correctGreen : AppColors.incorrectRed,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: _isCorrect ? AppColors.correctGreen : AppColors.incorrectRed,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCorrect ? 'Correct Answer!' : 'Incorrect!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect ? AppColors.correctGreen : AppColors.incorrectRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Concept Tested: ${currentQuestion.concept}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentQuestion.explanation,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Navigation Action Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasAnswered ? _onNextPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                  child: Text(
                    currentIndex < questions.length - 1 ? 'NEXT QUESTION' : 'SUBMIT QUIZ',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
