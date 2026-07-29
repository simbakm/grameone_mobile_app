import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/quiz_engine.dart';
import '../../theme/app_theme.dart';
import 'analytics_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';
import 'topics_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _showBadgesDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: AppColors.royalGold),
            SizedBox(width: 8),
            Text('Learner Badges'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: provider.badges.isEmpty
              ? const Text('Complete your first quiz to earn badges!')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.badges.length,
                  itemBuilder: (context, index) {
                    final badge = provider.badges[index];
                    return ListTile(
                      leading: Icon(
                        badge.isUnlocked ? Icons.workspace_premium : Icons.lock_outline,
                        color: badge.isUnlocked ? AppColors.badgeUnlocked : AppColors.badgeLocked,
                        size: 32,
                      ),
                      title: Text(
                        badge.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: badge.isUnlocked ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                        ),
                      ),
                      subtitle: Text(badge.description),
                      trailing: badge.isUnlocked
                          ? const Icon(Icons.check_circle, color: AppColors.correctGreen)
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final grade = provider.settings?.selectedGrade ?? 7;
    final isActivated = provider.licenseInfo?.isActivated ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GrameOne Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Banner
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Learner!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActivated ? AppColors.correctGreen : AppColors.royalGold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActivated
                                ? 'Grade $grade Active • Full Offline Access'
                                : 'Free demo mode • Activate for full access',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6 Action Grid Cards (2 Columns)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _buildDashboardGridCard(
                    context: context,
                    icon: Icons.import_contacts,
                    title: 'Topics',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TopicsScreen()),
                      );
                    },
                  ),
                  _buildDashboardGridCard(
                    context: context,
                    icon: Icons.quiz_outlined,
                    title: 'Revision Test',
                    onTap: () async {
                      await provider.startQuiz(testType: TestType.revision);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      );
                    },
                  ),
                  _buildDashboardGridCard(
                    context: context,
                    icon: Icons.calendar_today_rounded,
                    title: 'Daily Challenge',
                    onTap: () async {
                      await provider.startQuiz(testType: TestType.dailyChallenge);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      );
                    },
                  ),
                  _buildDashboardGridCard(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    title: 'Analytics',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
                      );
                    },
                  ),
                  _buildDashboardGridCard(
                    context: context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Badges',
                    onTap: () => _showBadgesDialog(context),
                  ),
                  _buildDashboardGridCard(
                    context: context,
                    icon: Icons.family_restroom,
                    title: 'Parent View',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.royalGold,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.overallScore.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepMaroon,
                              ),
                            ),
                            const Text(
                              'Overall Score',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.emeraldGreen,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.testsDone}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepMaroon,
                              ),
                            ),
                            const Text(
                              'Tests Done',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGridCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: AppColors.deepMaroon,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
