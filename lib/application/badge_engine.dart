import '../data/database/app_database.dart';
import '../data/models/models.dart';
import '../data/repositories/analytics_repository.dart';

class BadgeEngine {
  final AnalyticsRepository analyticsRepository;
  final AppDatabase dbProvider;

  BadgeEngine({AnalyticsRepository? analyticsRepository, AppDatabase? dbProvider})
      : analyticsRepository = analyticsRepository ?? AnalyticsRepository(),
        dbProvider = dbProvider ?? AppDatabase.instance;

  static const List<Map<String, String>> defaultBadges = [
    {
      'key': 'FIRST_TEST',
      'title': 'First Steps',
      'description': 'Completed your very first test!',
      'icon': 'emoji_events',
    },
    {
      'key': 'TEN_TESTS',
      'title': 'Practice Champion',
      'description': 'Completed 10 revision tests!',
      'icon': 'military_tech',
    },
    {
      'key': '100_CORRECT',
      'title': 'Century Club',
      'description': 'Answered 100 questions correctly!',
      'icon': 'stars',
    },
    {
      'key': '500_CORRECT',
      'title': 'Scholar Master',
      'description': 'Answered 500 questions correctly!',
      'icon': 'workspace_premium',
    },
    {
      'key': '7_DAY_STREAK',
      'title': 'Weekly Warrior',
      'description': 'Maintained a 7-day study streak!',
      'icon': 'local_fire_department',
    },
    {
      'key': '30_DAY_STREAK',
      'title': 'Monthly Legend',
      'description': 'Maintained a 30-day study streak!',
      'icon': 'verified',
    },
    {
      'key': 'SUBJECT_MASTER',
      'title': 'Subject Master',
      'description': 'Achieved 90%+ overall score in a subject!',
      'icon': 'psychology',
    },
  ];

  Future<List<BadgeModel>> evaluateAndGetBadges() async {
    final db = await dbProvider.database;
    final int totalTests = await analyticsRepository.getTotalTestsCount();
    final int totalCorrect = await analyticsRepository.getTotalCorrectAnswersCount();
    final int streakDays = await analyticsRepository.getStudyStreakDays();

    DateTime now = DateTime.now();

    for (var b in defaultBadges) {
      final String key = b['key']!;
      bool shouldUnlock = false;

      if (key == 'FIRST_TEST' && totalTests >= 1) shouldUnlock = true;
      if (key == 'TEN_TESTS' && totalTests >= 10) shouldUnlock = true;
      if (key == '100_CORRECT' && totalCorrect >= 100) shouldUnlock = true;
      if (key == '500_CORRECT' && totalCorrect >= 500) shouldUnlock = true;
      if (key == '7_DAY_STREAK' && streakDays >= 7) shouldUnlock = true;
      if (key == '30_DAY_STREAK' && streakDays >= 30) shouldUnlock = true;

      // Insert or Update badge record
      final List<Map<String, dynamic>> existing = await db.query(
        'badges',
        where: 'badge_key = ?',
        whereArgs: [key],
      );

      if (existing.isEmpty) {
        await db.insert('badges', {
          'id': 'badge_$key',
          'badge_key': key,
          'title': b['title'],
          'description': b['description'],
          'icon_name': b['icon'],
          'unlocked_at': shouldUnlock ? now.toIso8601String() : null,
        });
      } else if (shouldUnlock && existing.first['unlocked_at'] == null) {
        await db.update(
          'badges',
          {'unlocked_at': now.toIso8601String()},
          where: 'badge_key = ?',
          whereArgs: [key],
        );
      }
    }

    final List<Map<String, dynamic>> badgeMaps = await db.query('badges');
    return badgeMaps.map((m) => BadgeModel.fromMap(m)).toList();
  }
}
