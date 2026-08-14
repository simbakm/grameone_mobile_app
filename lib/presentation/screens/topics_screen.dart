import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../theme/app_theme.dart';
import '../widgets/no_content_widget.dart';
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
    'Mathematics',
    'English Language',
    'Indigenous Language',
    'Agriculture, Science and Technology and ICT',
    'Social Sciences',
    'Physical Education and Arts',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject ?? 'Mathematics';
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
                            value: _allSubjects.contains(_selectedSubject) ? _selectedSubject : _allSubjects.first,
                            isExpanded: true,
                            items: _allSubjects.map((String sub) {
                              String label = sub;
                              if (sub == 'Indigenous Language') {
                                label = 'Indigenous ($selectedLang)';
                              } else if (sub == 'Agriculture, Science and Technology and ICT') {
                                label = 'Agriculture, Science & ICT';
                              } else if (sub == 'Physical Education and Arts') {
                                label = 'Physical Education & Arts';
                              }
                              return DropdownMenuItem<String>(
                                value: sub,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.emeraldGreen,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                        ? NoContentWidget(subjectName: _selectedSubject)
                        : ListView.builder(
                            itemCount: _dynamicTopics.length,
                            itemBuilder: (context, index) {
                              final topicTitle = _dynamicTopics[index];
                              final int number = index + 1;
                              final progress = _progressMap[topicTitle];

                              Color badgeColor = AppColors.surfaceLight;
                              Color textColor = AppColors.textPrimaryLight;
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
}
