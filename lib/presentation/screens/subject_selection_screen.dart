import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../theme/app_theme.dart';
import 'topics_screen.dart';

/// Intermediate "Select a Subject" screen shown when the learner taps the
/// Subjects card on the dashboard.  Each subject is presented as a large,
/// tappable card – styled exactly like the main dashboard grid – with a
/// distinct accent colour and icon.  Tapping a card navigates to
/// [TopicsScreen] pre-filtered to that subject.
class SubjectSelectionScreen extends StatelessWidget {
  const SubjectSelectionScreen({super.key});

  // ── Subject metadata ────────────────────────────────────────────────────
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
      subtitle: null, // resolved dynamically from settings
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
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Choose a subject to browse its topics',
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
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final meta = _subjects[index];
                  final isIndigenous = meta.key == 'Indigenous Language';
                  final subtitle = isIndigenous
                      ? selectedLang // e.g. "Shona"
                      : meta.subtitle!;
                  final label = isIndigenous
                      ? 'Indigenous\nLanguage'
                      : meta.key;

                  return _SubjectCard(
                    meta: meta,
                    label: label,
                    subtitle: subtitle,
                    isIndigenous: isIndigenous,
                    selectedLang: selectedLang,
                    onTap: () {
                      provider.setActiveSubject(meta.key);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TopicsScreen(initialSubject: meta.key),
                        ),
                      );
                    },
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

// ── Internal card widget ─────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.meta,
    required this.label,
    required this.subtitle,
    required this.isIndigenous,
    required this.selectedLang,
    required this.onTap,
  });

  final _SubjectMeta meta;
  final String label;
  final String subtitle;
  final bool isIndigenous;
  final String selectedLang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: meta.accent.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: meta.accent.withAlpha(60), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: meta.accent.withAlpha(30),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accent icon bubble
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: meta.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: meta.accent.withAlpha(80)),
                ),
                child: Icon(meta.icon, size: 22, color: meta.accent),
              ),
              const SizedBox(height: 6),

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
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 2),

              // Subtitle line
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isIndigenous ? 11 : 10,
                  fontWeight: isIndigenous ? FontWeight.bold : FontWeight.normal,
                  color: isIndigenous ? meta.accent : AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

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
