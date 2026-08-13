import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/quiz_engine.dart';
import '../../theme/app_theme.dart';
import 'quiz_screen.dart';

/// A focused subject-picker shown exclusively for the Revision Test flow.
/// Tapping a subject card immediately starts a revision quiz based on
/// concepts the learner has already covered — no extra screens in between.
class RevisionSubjectSelectionScreen extends StatelessWidget {
  const RevisionSubjectSelectionScreen({super.key});

  static const List<_SubjectMeta> _subjects = [
    _SubjectMeta(
      key: 'Science',
      icon: Icons.science_outlined,
      accent: AppColors.scienceTeal,
      background: AppColors.bgScience,
      subtitle: 'Nature, environment & experiments',
    ),
    _SubjectMeta(
      key: 'Mathematics',
      icon: Icons.calculate_outlined,
      accent: AppColors.mathBlue,
      background: AppColors.bgMath,
      subtitle: 'Numbers, shapes & measurement',
    ),
    _SubjectMeta(
      key: 'English',
      icon: Icons.menu_book_outlined,
      accent: AppColors.englishPurple,
      background: AppColors.bgEnglish,
      subtitle: 'Grammar, reading & vocabulary',
    ),
    _SubjectMeta(
      key: 'Agriculture',
      icon: Icons.grass_outlined,
      accent: AppColors.emeraldGreen,
      background: AppColors.lightGreen,
      subtitle: 'Farming, crops & soil science',
    ),
    _SubjectMeta(
      key: 'Social Science',
      icon: Icons.public_outlined,
      accent: AppColors.socialRose,
      background: AppColors.bgSocial,
      subtitle: 'Heritage, culture & government',
    ),
    _SubjectMeta(
      key: 'Indigenous Language',
      icon: Icons.record_voice_over_outlined,
      accent: AppColors.royalGold,
      background: AppColors.lightGold,
      subtitle: null, // resolved from settings
    ),
  ];

  Future<void> _startRevision(
    BuildContext context,
    AppProvider provider,
    String subject,
  ) async {
    provider.setActiveSubject(subject);

    // Show loading indicator while quiz generates
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
                Text('Preparing revision test…'),
              ],
            ),
          ),
        ),
      ),
    );

    await provider.startQuiz(
      testType: TestType.revision,
      subject: subject,
    );

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loader

    if (provider.currentQuizQuestions.isEmpty) {
      // No concepts covered yet for this subject
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.royalGold),
              SizedBox(width: 8),
              Text('Nothing to Revise Yet'),
            ],
          ),
          content: Text(
            'You haven\'t covered any $subject concepts yet.\n\n'
            'Complete some topic exercises first, then come back to revise!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final selectedLang = provider.currentIndigenousLang;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision Test'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header description
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightGold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.royalGold.withAlpha(100)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.quiz_outlined, color: AppColors.royalGold, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select a subject to start a revision test based on concepts you have covered so far.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimaryLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subject grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final meta = _subjects[index];
                  final isIndigenous = meta.key == 'Indigenous Language';
                  final subtitle = isIndigenous ? selectedLang : meta.subtitle!;
                  final label = isIndigenous ? 'Indigenous\nLanguage' : meta.key;

                  return _RevisionSubjectCard(
                    meta: meta,
                    label: label,
                    subtitle: subtitle,
                    onTap: () => _startRevision(context, provider, meta.key),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _RevisionSubjectCard extends StatelessWidget {
  const _RevisionSubjectCard({
    required this.meta,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final _SubjectMeta meta;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: meta.accent.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: meta.accent.withAlpha(80), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: meta.accent.withAlpha(30),
        child: Container(
          decoration: BoxDecoration(
            color: meta.background.withAlpha(60),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon bubble
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: meta.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: meta.accent.withAlpha(100), width: 1.5),
                ),
                child: Icon(meta.icon, size: 24, color: meta.accent),
              ),
              const SizedBox(height: 8),

              // Subject name
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),

              // Subtitle — clamp to 1 line
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: meta.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // "Start Revision" pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: meta.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Start Revision',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _SubjectMeta {
  const _SubjectMeta({
    required this.key,
    required this.icon,
    required this.accent,
    required this.background,
    required this.subtitle,
  });

  final String key;
  final IconData icon;
  final Color accent;
  final Color background;
  final String? subtitle;
}
