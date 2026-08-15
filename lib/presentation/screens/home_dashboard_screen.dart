import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/app_provider.dart';
import '../../application/quiz_engine.dart';
import '../../data/models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/whatsapp_utils.dart';
import 'activation_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'quiz_screen.dart';
import 'revision_subject_selection_screen.dart';
import 'settings_screen.dart';
import 'subject_selection_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {

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

  /// Simple switcher popup showing only registered learners (only when 2+ exist)
  void _showSimpleLearnerSwitcher(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.swap_horiz, color: AppColors.emeraldGreen),
            SizedBox(width: 8),
            Text('Switch Learner'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: provider.learnerProfiles.map((profile) {
            final isSelected = provider.activeLearner?.id == profile.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.lightGreen : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.emeraldGreen : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Text(profile.avatar, style: const TextStyle(fontSize: 24)),
                title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Grade ${profile.grade} • ${profile.indigenousLanguage}'),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.emeraldGreen) : null,
                onTap: () {
                  provider.switchLearnerProfile(profile);
                  Navigator.of(ctx).pop();
                },
              ),
            );
          }).toList(),
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

  Widget _buildDismissableExpiryAlert(BuildContext context, AppProvider provider, LicenseInfo? license) {
    // Use per-learner expiry if available, else fall back to global license
    final activeLearner = provider.activeLearner;
    final DateTime? effectiveExpiry = (activeLearner != null && activeLearner.expiryDate != null)
        ? activeLearner.expiryDate
        : license?.expiryDate;

    if (effectiveExpiry == null) return Container();
    // If learner has no activation at all, don't show banner
    if (activeLearner != null && !activeLearner.isActivated && (license == null || !license.isActivated)) {
      return Container();
    }

    final now = DateTime.now();
    final remaining = effectiveExpiry.difference(now);
    final days = remaining.inDays;
    final hours = remaining.inHours;

    int thresholdDay;
    Color bannerBg = AppColors.lightGreen;
    Color textColor = AppColors.emeraldGreen;
    IconData icon = Icons.verified_user_outlined;
    String text = '';

    if (remaining.isNegative) {
      thresholdDay = 0;
      bannerBg = AppColors.lightMaroon;
      textColor = AppColors.incorrectRed;
      icon = Icons.warning_amber_rounded;
      text = 'License Expired. Renew in settings.';
    } else if (days <= 1) {
      thresholdDay = 1;
      bannerBg = AppColors.lightMaroon;
      textColor = AppColors.incorrectRed;
      icon = Icons.alarm;
      text = 'License Renewal Urgent: $hours hours remaining!';
    } else if (days <= 3) {
      thresholdDay = 3;
      bannerBg = Colors.orange.shade50;
      textColor = Colors.deepOrange;
      icon = Icons.timer_outlined;
      text = 'License Renewal: $days days remaining';
    } else if (days <= 7) {
      thresholdDay = 7;
      bannerBg = AppColors.lightGold;
      textColor = AppColors.royalGold;
      icon = Icons.event_available;
      text = 'License Renewal: 1 week remaining ($days days)';
    } else if (days <= 14) {
      thresholdDay = 14;
      bannerBg = AppColors.lightGold;
      textColor = AppColors.royalGold;
      icon = Icons.event_available;
      text = 'License Renewal: 2 weeks remaining ($days days)';
    } else if (days <= 28) {
      thresholdDay = 28;
      bannerBg = AppColors.lightGreen;
      textColor = AppColors.emeraldGreen;
      icon = Icons.event_available;
      text = 'License Renewal: 4 weeks remaining ($days days)';
    } else {
      return Container(); // Hide banner completely if > 28 days remaining
    }

    // Do not show if learner already dismissed this threshold during session
    if (provider.dismissedExpiryThresholdDay == thresholdDay) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha(120), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: textColor),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () => provider.dismissExpiryThreshold(thresholdDay),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredLicenseLockView(BuildContext context, AppProvider provider) {
    final deviceId = provider.licenseInfo?.deviceId ?? 'UNKNOWN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('GrameOne - License Expired'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.lightMaroon,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_outlined,
                  size: 64,
                  color: AppColors.incorrectRed,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'License Expired',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepMaroon,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your GrameOne access license has expired. Please enter a valid activation code or renew your subscription to continue using lessons and quizzes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Device ID Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Text('Device ID:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 4),
                    SelectableText(
                      deviceId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Multi-Account Switch Prompt if other profiles exist on device
              if (provider.learnerProfiles.length > 1) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.emeraldGreen, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.swap_horiz, color: AppColors.emeraldGreen),
                          SizedBox(width: 6),
                          Text(
                            'Switch Account',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'License for ${provider.activeLearner?.name ?? 'this user'} has expired. You can switch to another child profile with a valid license instead of locking the app.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.3),
                      ),
                      const SizedBox(height: 14),
                      ...provider.learnerProfiles
                          .where((p) => p.id != provider.activeLearner?.id)
                          .map((otherProfile) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      provider.switchLearnerProfile(otherProfile);
                                    },
                                    icon: Text(otherProfile.avatar, style: const TextStyle(fontSize: 18)),
                                    label: Text('Switch to ${otherProfile.name} (Grade ${otherProfile.grade})'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.emeraldGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActivationScreen()),
                    );
                  },
                  icon: const Icon(Icons.key),
                  label: const Text('RENEW LICENSE NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    WhatsAppUtils.openSupportWhatsApp(
                      context: context,
                      message: 'Hello GrameOne Support, I need assistance renewing my license for Device ID: $deviceId.',
                    );
                  },
                  icon: const Icon(Icons.chat, color: Color(0xFF16A34A)),
                  label: const Text('Contact Support on WhatsApp', style: TextStyle(color: Color(0xFF16A34A))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final license = provider.licenseInfo;
    // Per-learner expiry check — only lock out the ACTIVE learner, not all
    final bool isExpired = provider.isActiveLearnerExpired;

    if (isExpired) {
      return _buildExpiredLicenseLockView(context, provider);
    }

    final activeLearner = provider.activeLearner;
    final grade = provider.currentGrade;
    final isActivated = license?.isActivated ?? false;
    final hasMultipleLearners = provider.learnerProfiles.length >= 2;

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
              // Clean Welcome Banner
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeLearner?.avatar ?? '🧒',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Welcome, ${activeLearner?.name ?? "Learner"}!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepMaroon,
                                ),
                              ),
                            ],
                          ),
                          // Show switcher ONLY if 2 or more learners exist
                          if (hasMultipleLearners) ...[
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showSimpleLearnerSwitcher(context, provider),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.emeraldGreen),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.swap_horiz, size: 16, color: AppColors.emeraldGreen),
                                    SizedBox(width: 4),
                                    Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
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

              const SizedBox(height: 12),

              // Dismissable threshold alert banner (dismissable by user)
              _buildDismissableExpiryAlert(context, provider, provider.licenseInfo),

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
                    title: 'Subjects',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SubjectSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardGridCard(
                    context: context,
                    icon: Icons.quiz_outlined,
                    title: 'Revision Test',
                    onTap: () {
                      // Revision Test: pick subject then start quiz immediately
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RevisionSubjectSelectionScreen(),
                        ),
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
                              Icons.local_fire_department_rounded,
                              color: Colors.deepOrange,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.studyStreak} Days',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepMaroon,
                              ),
                            ),
                            const Text(
                              'Study Streak',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: AppColors.emeraldGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
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
