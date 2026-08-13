import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../theme/app_theme.dart';
import 'units_screen.dart';

class TopicsScreen extends StatefulWidget {
  final String? initialSubject;
  const TopicsScreen({super.key, this.initialSubject});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  late String _selectedSubject;
  List<String> _dynamicTopics = [];
  Map<String, TopicUnitProgress> _progressMap = {};
  bool _isLoading = true;

  static const List<String> _allSubjects = [
    'Science',
    'Mathematics',
    'English',
    'Agriculture',
    'Social Science',
    'Indigenous Language',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject ?? 'Science';
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final grade = provider.currentGrade;
    final learnerId = provider.activeLearner?.id;

    final topics = await provider.questionRepository.getTopicsForSubject(
      grade: grade,
      subject: _selectedSubject,
    );

    final progress = await provider.analyticsRepository.getTopicProgressMap(
      grade: grade,
      subject: _selectedSubject,
      learnerProfileId: learnerId,
    );

    if (mounted) {
      setState(() {
        _dynamicTopics = topics;
        _progressMap = progress;
        _isLoading = false;
      });
    }
  }

  void _onSubjectChanged(String? newSubject) {
    if (newSubject != null && newSubject != _selectedSubject) {
      setState(() {
        _selectedSubject = newSubject;
      });
      Provider.of<AppProvider>(context, listen: false).setActiveSubject(newSubject);
      _loadTopics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final selectedLang = provider.currentIndigenousLang;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topics'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Subject Filter Dropdown
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: AppColors.emeraldGreen),
                      const SizedBox(width: 12),
                      const Text(
                        'Subject: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubject,
                            isExpanded: true,
                            items: _allSubjects.map((String sub) {
                              return DropdownMenuItem<String>(
                                value: sub,
                                child: Text(
                                  sub == 'Indigenous Language'
                                      ? 'Indigenous ($selectedLang)'
                                      : sub,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.emeraldGreen,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _onSubjectChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dynamic Topic List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.emeraldGreen),
                      )
                    : _dynamicTopics.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _dynamicTopics.length,
                            itemBuilder: (context, index) {
                              final topicTitle = _dynamicTopics[index];
                              final int number = index + 1;
                              final progress = _progressMap[topicTitle];

                              Color badgeColor = AppColors.borderLight;
                              Color textColor = AppColors.textSecondaryLight;
                              String badgeText = 'Not Started';
                              IconData badgeIcon = Icons.hourglass_empty;

                              if (progress != null && progress.status == ProgressStatus.completed) {
                                badgeColor = AppColors.lightGreen;
                                textColor = AppColors.emeraldGreen;
                                badgeText = '✓ Done (${progress.scorePercentage.toStringAsFixed(0)}%)';
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
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => UnitsScreen(
                                          subject: _selectedSubject,
                                          topic: topicTitle,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                                                topicTitle,
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
                                          Icons.chevron_right,
                                          color: AppColors.emeraldGreen,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.topic_outlined, size: 56, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              'No Topics Found for $_selectedSubject',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ensure you have downloaded the content package for your grade.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
