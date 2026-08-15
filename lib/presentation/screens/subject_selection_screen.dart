import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';
import 'topics_screen.dart';

/// "Select a Subject" screen matching original elegant centered card design (Screenshot 1).
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
      subtitle: 'Numbers, shapes & measurement',
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
      subtitle: null, // Displays selected language name underneath (e.g. Shona)
    ),
    _SubjectMeta(
      key: 'Agriculture, Science and Technology and ICT',
      displayName: 'Agriculture, Science & ICT',
      icon: Icons.science_outlined,
      accent: AppColors.scienceTeal,
      background: AppColors.bgScience,
      subtitle: 'Farming, nature, computing & tech',
    ),
    _SubjectMeta(
      key: 'Social Sciences',
      displayName: 'Social Sciences',
      icon: Icons.public_outlined,
      accent: AppColors.socialRose,
      background: AppColors.bgSocial,
      subtitle: 'Heritage, culture & government',
    ),
    _SubjectMeta(
      key: 'Physical Education and Arts',
      displayName: 'Physical Education & Arts',
      icon: Icons.sports_soccer_outlined,
      accent: AppColors.emeraldGreen,
      background: AppColors.lightGreen,
      subtitle: 'Fitness, sports, music & arts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final selectedLang = provider.currentIndigenousLang;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Subject'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header hint
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Choose a subject to browse its topics',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),

              // 2-column subject grid (Screenshot 1 design)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final meta = _subjects[index];
                  final isIndigenous = meta.key == 'Indigenous Language';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: meta.accent.withAlpha(70),
                        width: 1.5,
                      ),
                    ),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        provider.setActiveSubject(meta.key);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TopicsScreen(initialSubject: meta.key),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Centered circular icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: meta.accent.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(meta.icon, color: meta.accent, size: 26),
                            ),
                            const SizedBox(height: 12),

                            // Centered Subject Title
                            Text(
                              isIndigenous ? 'Indigenous Language' : meta.displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Subtitle underneath
                            if (isIndigenous)
                              Text(
                                selectedLang,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.royalGold,
                                ),
                              )
                            else if (meta.subtitle != null)
                              Text(
                                meta.subtitle!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
