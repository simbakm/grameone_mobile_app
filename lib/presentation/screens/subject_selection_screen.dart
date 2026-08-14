import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';
import 'topics_screen.dart';

/// Intermediate "Select a Subject" screen shown when the learner taps the
/// Subjects card on the dashboard. Each subject is presented as a large,
/// tappable card with official ZIMSEC subject names.
class SubjectSelectionScreen extends StatelessWidget {
  const SubjectSelectionScreen({super.key});

  // ── Official ZIMSEC Core Subjects ──────────────────────────────────────────
  static const List<_SubjectMeta> _subjects = [
    _SubjectMeta(
      key: 'Mathematics',
      displayName: 'Mathematics',
      icon: Icons.calculate_outlined,
      accent: AppColors.mathBlue,
      background: AppColors.bgMath,
      subtitle: 'Numbers, operations, shapes & measurement',
    ),
    _SubjectMeta(
      key: 'English Language',
      displayName: 'English Language',
      icon: Icons.menu_book_outlined,
      accent: AppColors.englishPurple,
      background: AppColors.bgEnglish,
      subtitle: 'Grammar, reading & vocabulary',
    ),
    _SubjectMeta(
      key: 'Indigenous Language',
      displayName: 'Indigenous Language',
      icon: Icons.record_voice_over_outlined,
      accent: AppColors.royalGold,
      background: AppColors.lightGold,
      subtitle: null, // resolved dynamically from settings
    ),
    _SubjectMeta(
      key: 'Agriculture, Science and Technology and ICT',
      displayName: 'Agriculture, Science and Tech & ICT',
      icon: Icons.science_outlined,
      accent: AppColors.scienceTeal,
      background: AppColors.bgScience,
      subtitle: 'Farming, nature, computing & technology',
    ),
    _SubjectMeta(
      key: 'Social Sciences',
      displayName: 'Social Sciences',
      icon: Icons.public_outlined,
      accent: AppColors.socialRose,
      background: AppColors.bgSocial,
      subtitle: 'Heritage, culture, family & community',
    ),
    _SubjectMeta(
      key: 'Physical Education and Arts',
      displayName: 'Physical Education & Arts',
      icon: Icons.sports_soccer_outlined,
      accent: AppColors.emeraldGreen,
      background: AppColors.lightGreen,
      subtitle: 'Fitness, sports, music & visual arts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final selectedLang = provider.settings?.selectedIndigenousLang ?? 'Shona';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Subject'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header hint
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Choose a ZIMSEC subject to browse topics & practice',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),

              // 2-column subject grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final meta = _subjects[index];
                  final isIndigenous = meta.key == 'Indigenous Language';
                  final titleText = isIndigenous
                      ? 'Indigenous Language ($selectedLang)'
                      : meta.displayName;
                  final subtitleText = isIndigenous
                      ? 'Shona, Ndebele & local languages'
                      : (meta.subtitle ?? '');

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    shadowColor: Colors.black.withAlpha(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: meta.accent.withAlpha(100),
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        provider.setActiveSubject(meta.key);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TopicsScreen(initialSubject: meta.key),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: meta.background,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon circle
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: meta.accent.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(meta.icon, color: meta.accent, size: 24),
                            ),
                            const Spacer(),

                            // Subject title
                            Text(
                              titleText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Subtitle
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryLight,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectMeta {
  final String key;
  final String displayName;
  final IconData icon;
  final Color accent;
  final Color background;
  final String? subtitle;

  const _SubjectMeta({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.accent,
    required this.background,
    this.subtitle,
  });
}
