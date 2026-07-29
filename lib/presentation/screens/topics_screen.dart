import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/quiz_engine.dart';
import '../../theme/app_theme.dart';
import 'quiz_screen.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  String _selectedSubject = 'Science';

  /// Topics for each non-indigenous subject. Indigenous Language topics
  /// are resolved at build-time from the learner's selected language.
  static const Map<String, List<Map<String, String>>> _baseTopicsMap = {
    'Science': [
      {
        'title': 'Health and Hygiene Practices',
        'subtitle': 'Human health, hygiene and wellbeing',
      },
      {
        'title': 'Food and Nutrition',
        'subtitle': 'Diet, storage and food preparation',
      },
      {
        'title': 'Crops, Plants and Animals',
        'subtitle': 'Plant and animal science',
      },
      {
        'title': 'Environmental Awareness and Conservation',
        'subtitle': 'Environment and natural resources',
      },
      {
        'title': 'Tools, Equipment and Implements',
        'subtitle': 'Tools, technology and uses',
      },
    ],
    'Mathematics': [
      {
        'title': 'Numbers and Operations',
        'subtitle': 'Addition, subtraction, fractions & decimals',
      },
      {
        'title': 'Measures and Geometry',
        'subtitle': 'Area, perimeter, angles & shape properties',
      },
    ],
    'English': [
      {
        'title': 'Grammar and Structure',
        'subtitle': 'Parts of speech, sentence building & punctuation',
      },
      {
        'title': 'Reading and Comprehension',
        'subtitle': 'Comprehension, inference & vocabulary',
      },
    ],
    'Agriculture': [
      {
        'title': 'Soil Science and Crops',
        'subtitle': 'Soil fertility, composting & crop care',
      },
      {
        'title': 'Farm Management',
        'subtitle': 'Record keeping, tools & livestock',
      },
    ],
    'Social Science': [
      {
        'title': 'Heritage and Culture',
        'subtitle': 'National monuments, symbols & history',
      },
      {
        'title': 'Government and Citizenship',
        'subtitle': 'Civic rights, government structures & democracy',
      },
    ],
  };

  /// Language-specific topic lists whose 'title' values match DB topic names exactly.
  static const Map<String, List<Map<String, String>>> _indigenousTopicsMap = {
    'Shona': [
      {
        'title': 'Tsumo neMadimikira (Shona)',
        'subtitle': 'Tsumo, madimikira nezvimiro zvechishona',
      },
      {
        'title': 'Madimikira echiShona',
        'subtitle': 'Zvirevo, zvifananidzo nemashoko akajeka',
      },
    ],
    'Ndebele': [
      {
        'title': 'Izaga nGezitsho (Ndebele)',
        'subtitle': 'Izaga, izitsho nohlelo lwesiNdebele',
      },
      {
        'title': 'Izitsho zesiNdebele',
        'subtitle': 'Izitsho, imifanekiso nezincazelo',
      },
    ],
    'Tonga': [
      {
        'title': 'Tshisusu ne ZyaChitonga',
        'subtitle': 'Ulimi, makani alimwi zyamizeezo yaChitonga',
      },
      {
        'title': 'Language & Culture (Tonga)',
        'subtitle': 'Chitonga culture, proverbs and daily life',
      },
    ],
  };

  List<Map<String, String>> _topicsFor(String subject, String selectedLang) {
    if (subject == 'Indigenous Language') {
      return _indigenousTopicsMap[selectedLang] ??
          _indigenousTopicsMap['Shona']!;
    }
    return _baseTopicsMap[subject] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final selectedLang = provider.settings?.selectedIndigenousLang ?? 'Shona';
    final topics = _topicsFor(_selectedSubject, selectedLang);
    final allSubjects = [
      ...(_baseTopicsMap.keys),
      'Indigenous Language',
    ];

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: AppColors.deepMaroon),
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
                            items: allSubjects.map((String sub) {
                              return DropdownMenuItem<String>(
                                value: sub,
                                child: Text(
                                  sub == 'Indigenous Language'
                                      ? 'Indigenous ($selectedLang)'
                                      : sub,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepMaroon,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSubject = val;
                                });
                                provider.setActiveSubject(val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Topic List matching reference design
              Expanded(
                child: ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final item = topics[index];
                    final int number = index + 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await provider.startQuiz(
                            testType: TestType.practice,
                            subject: _selectedSubject,
                            topic: item['title'],
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const QuizScreen()),
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
                                  color: AppColors.lightGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$number',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.emeraldGreen,
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
                                      item['title']!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitle']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.deepMaroon,
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
