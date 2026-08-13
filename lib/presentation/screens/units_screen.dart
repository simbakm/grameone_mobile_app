import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/quiz_engine.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../theme/app_theme.dart';
import 'quiz_screen.dart';
import 'topics_screen.dart';

class UnitsScreen extends StatefulWidget {
  final String subject;
  final String topic;

  const UnitsScreen({
    super.key,
    required this.subject,
    required this.topic,
  });

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  List<String> _units = [];
  Map<String, TopicUnitProgress> _unitProgressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final grade = provider.currentGrade;
    final learnerId = provider.activeLearner?.id;

    try {
      final units = await provider.questionRepository.getUnitsForTopic(
        grade: grade,
        subject: widget.subject,
        topic: widget.topic,
      );

      final progress = await provider.analyticsRepository.getUnitProgressMap(
        grade: grade,
        subject: widget.subject,
        topic: widget.topic,
        learnerProfileId: learnerId,
      );

      if (mounted) {
        setState(() {
          _units = units;
          _unitProgressMap = progress;
        });
      }
    } catch (e) {
      debugPrint('Error loading units: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Returns true if ALL real units in this topic have been attempted at least once by the child
  bool get _allUnitsAttempted {
    if (_units.isEmpty) return false;
    return _units.every((u) {
      final p = _unitProgressMap[u];
      return p != null && p.totalQuestions > 0;
    });
  }

  int get _attemptedUnitsCount =>
      _units.where((u) => (_unitProgressMap[u]?.totalQuestions ?? 0) > 0).length;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigating back from Units always goes to TopicsScreen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => TopicsScreen(initialSubject: widget.subject),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightGreen, AppColors.emeraldGreen.withAlpha(20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.emeraldGreen.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subject.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emeraldGreen,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.topic,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select a unit below to start practice questions (max 20 per session)',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'Units',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepMaroon,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.emeraldGreen),
                      )
                    : _units.isEmpty
                        ? _buildEmptyState(context, provider)
                        : ListView.builder(
                            // +1 for the end-of-topic revision test card
                            itemCount: _units.length + 1,
                            itemBuilder: (context, index) {
                              // ── End-of-topic Revision Test card ──
                              if (index == _units.length) {
                                return _buildTopicRevisionCard(context, provider);
                              }

                              final unitTitle = _units[index];
                              final int number = index + 1;
                              final progress = _unitProgressMap[unitTitle];

                              Color badgeColor = AppColors.borderLight;
                              Color textColor = AppColors.textSecondaryLight;
                              String badgeText = 'Not Started';
                              IconData badgeIcon = Icons.hourglass_empty;

                              if (progress != null && progress.status == ProgressStatus.completed) {
                                badgeColor = AppColors.lightGreen;
                                textColor = AppColors.emeraldGreen;
                                badgeText = '✓ Completed (${progress.scorePercentage.toStringAsFixed(0)}%)';
                                badgeIcon = Icons.check_circle;
                              } else if (progress != null && progress.status == ProgressStatus.inProgress) {
                                badgeColor = AppColors.lightGold;
                                textColor = AppColors.royalGold;
                                badgeText = 'In Progress (${progress.scorePercentage.toStringAsFixed(0)}%)';
                                badgeIcon = Icons.timelapse;
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: progress?.status == ProgressStatus.completed
                                        ? AppColors.emeraldGreen.withAlpha(100)
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    await provider.startQuiz(
                                      testType: TestType.practice,
                                      subject: widget.subject,
                                      topic: widget.topic,
                                      unit: unitTitle,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: progress?.status == ProgressStatus.completed
                                                ? AppColors.lightGreen
                                                : AppColors.surfaceLight,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: progress?.status == ProgressStatus.completed
                                                  ? AppColors.emeraldGreen
                                                  : AppColors.borderLight,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$number',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: progress?.status == ProgressStatus.completed
                                                    ? AppColors.emeraldGreen
                                                    : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                unitTitle,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimaryLight,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: badgeColor,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(badgeIcon, size: 12, color: textColor),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          badgeText,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.play_circle_fill,
                                          color: AppColors.emeraldGreen,
                                          size: 28,
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

  /// End-of-Topic Revision Test card — locked until all units in this topic have been attempted at least once
  Widget _buildTopicRevisionCard(BuildContext context, AppProvider provider) {
    final unlocked = _allUnitsAttempted;
    final attemptedCount = _attemptedUnitsCount;
    final totalCount = _units.length;
    final remaining = totalCount - attemptedCount;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: BoxDecoration(
        gradient: unlocked
            ? const LinearGradient(
                colors: [Color(0xFF800020), Color(0xFF580016)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: unlocked ? null : AppColors.borderLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? AppColors.deepMaroon : AppColors.borderLight,
          width: 2,
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: AppColors.deepMaroon.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: unlocked
              ? () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Preparing topic revision test…'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  await provider.startQuiz(
                    testType: TestType.topicRevision,
                    subject: widget.subject,
                    topic: widget.topic,
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // dismiss loader
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  );
                }
              : () {
                  // Show locked message
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: const [
                          Icon(Icons.lock_outline, color: AppColors.royalGold),
                          SizedBox(width: 8),
                          Text('Not Unlocked Yet'),
                        ],
                      ),
                      content: Text(
                        'Attempt all $totalCount units in this topic first.\n\n'
                        'You have attempted $attemptedCount of $totalCount units. '
                        '$remaining more unit${remaining == 1 ? '' : 's'} to go!',
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: unlocked ? Colors.white.withAlpha(30) : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unlocked ? Colors.white.withAlpha(80) : AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    unlocked ? Icons.assignment_turned_in : Icons.lock_outline,
                    size: 26,
                    color: unlocked ? Colors.white : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Topic Revision Test',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: unlocked ? Colors.white : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlocked
                            ? 'Covers all ${_units.length} units • 40 questions • Random selection'
                            : 'Attempt all units to unlock ($attemptedCount/$totalCount done)',
                        style: TextStyle(
                          fontSize: 12,
                          color: unlocked ? Colors.white.withAlpha(200) : AppColors.textSecondaryLight,
                        ),
                      ),
                      if (unlocked) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🏆  40 Questions · All Units',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  unlocked ? Icons.play_circle_fill : Icons.lock,
                  size: 32,
                  color: unlocked ? Colors.white : AppColors.borderLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_alt_outlined, size: 56, color: AppColors.textSecondaryLight),
          const SizedBox(height: 16),
          Text(
            'All Units in ${widget.topic}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Practice all questions for this topic directly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await provider.startQuiz(
                testType: TestType.practice,
                subject: widget.subject,
                topic: widget.topic,
              );
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuizScreen()),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Topic Practice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
