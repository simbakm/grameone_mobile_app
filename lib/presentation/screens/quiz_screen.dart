import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../data/models/models.dart';
import '../../theme/app_theme.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _showComprehension = true;
  bool _showDiagram = true;

  void _onSelectOption(int questionIndex, QuestionOption option) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.selectOptionForQuestion(questionIndex, option.id);
  }

  Future<void> _submitQuiz(BuildContext context, AppProvider provider) async {
    final questions = provider.currentQuizQuestions;
    if (questions.isEmpty) return;

    final unansweredCount = questions.length - provider.userSelectedOptionIds.length;

    if (unansweredCount > 0) {
      // Find index of first unanswered question
      int firstUnansweredIndex = 0;
      for (int i = 0; i < questions.length; i++) {
        if (!provider.userSelectedOptionIds.containsKey(i)) {
          firstUnansweredIndex = i;
          break;
        }
      }

      // Jump to the unanswered question
      provider.jumpToQuestion(firstUnansweredIndex);

      // Block submission and inform learner
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.deepMaroon),
              SizedBox(width: 8),
              Text('Incomplete Test'),
            ],
          ),
          content: Text(
            'You cannot submit the test yet. You still have $unansweredCount unanswered question(s).\n\nWe have jumped to Question ${firstUnansweredIndex + 1} for you to answer.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen),
              child: const Text('OK, CONTINUE TEST'),
            ),
          ],
        ),
      );
      return;
    }

    final firstQ = questions.first;
    final attempt = await provider.finishQuiz(
      provider.currentTestType,
      firstQ.subject,
      firstQ.topic,
    );

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(attempt: attempt),
      ),
    );
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
    final selectedOptionId = provider.userSelectedOptionIds[currentIndex];
    final double progress = (provider.userSelectedOptionIds.length) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${currentQuestion.subject} - Q${currentIndex + 1}/${questions.length}'),
        actions: [
          TextButton.icon(
            onPressed: () => _submitQuiz(context, provider),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            label: const Text(
              'SUBMIT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar (Answers completed count)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
              minHeight: 6,
            ),

            // Top Question Quick Jump Selector Row
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              color: AppColors.surfaceLight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final isCurrent = index == currentIndex;
                  final isAnswered = provider.userSelectedOptionIds.containsKey(index);

                  Color chipColor = AppColors.borderLight;
                  Color textColor = AppColors.textSecondaryLight;

                  if (isCurrent) {
                    chipColor = AppColors.emeraldGreen;
                    textColor = Colors.white;
                  } else if (isAnswered) {
                    chipColor = AppColors.lightGreen;
                    textColor = AppColors.emeraldGreen;
                  }

                  return GestureDetector(
                    onTap: () => provider.jumpToQuestion(index),
                    child: Container(
                      width: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent ? AppColors.emeraldGreen : AppColors.borderLight,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Meta Concept Bar
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              avatar: const Icon(Icons.bookmark_outline, size: 16, color: AppColors.deepMaroon),
                              label: Text(
                                currentQuestion.topic,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: AppColors.lightGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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

                    // ── Reading Passage Toggle Control ──
                    if (currentQuestion.comprehensionText != null &&
                        currentQuestion.comprehensionText!.trim().isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _showComprehension = !_showComprehension),
                        icon: Icon(
                          _showComprehension ? Icons.auto_stories : Icons.menu_book,
                          size: 18,
                          color: AppColors.deepMaroon,
                        ),
                        label: Text(
                          _showComprehension ? 'Hide Reading Passage' : 'Show Reading Passage',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepMaroon),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.royalGold),
                          backgroundColor: AppColors.lightGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (_showComprehension) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.royalGold.withAlpha(120)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.menu_book, size: 18, color: AppColors.deepMaroon),
                                  SizedBox(width: 8),
                                  Text(
                                    'Reading Passage',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.deepMaroon,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text(
                                currentQuestion.comprehensionText!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],

                    // ── Picture / Diagram Toggle Control ──
                    if ((currentQuestion.imagePath != null && currentQuestion.imagePath!.trim().isNotEmpty) ||
                        (currentQuestion.diagramPath != null && currentQuestion.diagramPath!.trim().isNotEmpty)) ...[
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _showDiagram = !_showDiagram),
                        icon: Icon(
                          _showDiagram ? Icons.hide_image_outlined : Icons.image_outlined,
                          size: 18,
                          color: AppColors.emeraldGreen,
                        ),
                        label: Text(
                          _showDiagram ? 'Hide Diagram / Picture' : 'Show Diagram / Picture',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.emeraldGreen),
                          backgroundColor: AppColors.lightGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (_showDiagram) ...[
                        const SizedBox(height: 8),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderLight),
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 240),
                            width: double.infinity,
                            color: Colors.black12,
                            child: _buildImageWidget(
                              (currentQuestion.imagePath != null && currentQuestion.imagePath!.isNotEmpty)
                                  ? currentQuestion.imagePath!
                                  : currentQuestion.diagramPath!,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],

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

                    // Options List (Deferred Feedback — Highlights selected option without revealing correctness)
                    ...currentQuestion.options.map((option) {
                      final isSelected = selectedOptionId == option.id;
                      Color borderColor = isSelected ? AppColors.emeraldGreen : AppColors.borderLight;
                      Color bgColor = isSelected ? AppColors.lightGreen : AppColors.surfaceLight;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor, width: isSelected ? 2.5 : 1.5),
                          ),
                          color: bgColor,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _onSelectOption(currentIndex, option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppColors.emeraldGreen : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? AppColors.emeraldGreen : AppColors.borderLight,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.optionText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar (Previous & Next / Submit)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  // Previous Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: currentIndex > 0 ? () => provider.previousQuestion() : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('PREVIOUS'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Next / Submit Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (currentIndex < questions.length - 1) {
                          provider.nextQuestion();
                        } else {
                          _submitQuiz(context, provider);
                        }
                      },
                      icon: Icon(currentIndex < questions.length - 1 ? Icons.arrow_forward : Icons.check_circle_outline),
                      label: Text(currentIndex < questions.length - 1 ? 'NEXT' : 'SUBMIT TEST'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String pathOrUrl) {
    final cleanPath = pathOrUrl.trim();
    if (cleanPath.isEmpty) return const SizedBox.shrink();

    String resolvedUrl = cleanPath;

    // R2 private endpoint → route through backend media proxy
    if (cleanPath.contains('cloudflarestorage.com')) {
      final parts = cleanPath.split('/grameone/');
      final key = parts.length > 1 ? parts[1] : cleanPath;
      resolvedUrl = 'https://grame-one-back-end.onrender.com/api/media/files/$key';
    } else if (!cleanPath.startsWith('http://') && !cleanPath.startsWith('https://')) {
      // Check if it's a local file path on the device (e.g. from a bundled package db)
      final localFile = File(cleanPath);
      if (localFile.existsSync()) {
        return Image.file(
          localFile,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        );
      }
      // Relative key (e.g. "questions/abc.png") → proxy through backend
      resolvedUrl = 'https://grame-one-back-end.onrender.com/api/media/files/$cleanPath';
    }

    return Image.network(
      resolvedUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.emeraldGreen,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _buildFallbackImage(),
    );
  }

  Widget _buildFallbackImage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 36),
            SizedBox(height: 4),
            Text('🖼️ Diagram / Picture unavailable', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
