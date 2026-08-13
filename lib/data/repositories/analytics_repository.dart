import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/models.dart';

enum ProgressStatus { completed, inProgress, notStarted }

class TopicUnitProgress {
  final String title;
  final int totalQuestions;
  final double scorePercentage;
  final ProgressStatus status;

  TopicUnitProgress({
    required this.title,
    required this.totalQuestions,
    required this.scorePercentage,
    required this.status,
  });
}

class ConceptDetail {
  final String concept;
  final String subject;
  final int correctCount;
  final int totalCount;
  final double accuracyPercentage;

  ConceptDetail({
    required this.concept,
    required this.subject,
    required this.correctCount,
    required this.totalCount,
    required this.accuracyPercentage,
  });
}

class AnalyticsRepository {
  final AppDatabase dbProvider;

  AnalyticsRepository({AppDatabase? dbProvider})
      : dbProvider = dbProvider ?? AppDatabase.instance;

  Future<void> saveQuizAttempt({
    required QuizAttempt attempt,
    required List<AttemptAnswer> answers,
  }) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      await txn.insert(
        'quiz_attempts',
        attempt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (var ans in answers) {
        await txn.insert(
          'attempt_answers',
          ans.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Helper to build learner WHERE clause
  String _learnerClause(String? learnerProfileId, {bool hasWhere = true}) {
    if (learnerProfileId == null || learnerProfileId.isEmpty) return '';
    return hasWhere
        ? ' AND learner_profile_id = \'$learnerProfileId\''
        : ' WHERE learner_profile_id = \'$learnerProfileId\'';
  }

  Future<List<QuizAttempt>> getRecentAttempts({
    int limit = 5,
    String? learnerProfileId,
  }) async {
    final db = await dbProvider.database;
    final where = learnerProfileId != null && learnerProfileId.isNotEmpty
        ? 'learner_profile_id = ?'
        : null;
    final whereArgs = learnerProfileId != null && learnerProfileId.isNotEmpty
        ? [learnerProfileId]
        : null;
    final maps = await db.query(
      'quiz_attempts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => QuizAttempt.fromMap(m)).toList();
  }

  Future<int> getTotalTestsCount({String? learnerProfileId}) async {
    final db = await dbProvider.database;
    final clause = _learnerClause(learnerProfileId, hasWhere: false);
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM quiz_attempts$clause'),
    );
    return count ?? 0;
  }

  Future<int> getTotalCorrectAnswersCount({String? learnerProfileId}) async {
    final db = await dbProvider.database;
    final clause = _learnerClause(learnerProfileId, hasWhere: false);
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(correct_count) FROM quiz_attempts$clause'),
    );
    return count ?? 0;
  }

  Future<double> getOverallAverageScore({String? learnerProfileId}) async {
    final db = await dbProvider.database;
    final clause = _learnerClause(learnerProfileId, hasWhere: false);
    final result = await db.rawQuery(
      'SELECT SUM(correct_count) as total_correct, SUM(total_questions) as total_q FROM quiz_attempts$clause',
    );
    if (result.isNotEmpty && result.first['total_q'] != null) {
      final totalCorrect = (result.first['total_correct'] as num).toInt();
      final totalQ = (result.first['total_q'] as num).toInt();
      if (totalQ == 0) return 0.0;
      return (totalCorrect / totalQ) * 100;
    }
    return 0.0;
  }

  Future<int> getStudyStreakDays({String? learnerProfileId}) async {
    final db = await dbProvider.database;
    final clause = _learnerClause(learnerProfileId, hasWhere: false);
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT substr(timestamp, 1, 10) as date_str FROM quiz_attempts$clause ORDER BY date_str DESC',
    );
    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    for (var m in maps) {
      DateTime attemptDate = DateTime.parse(m['date_str'] as String);
      final difference = checkDate.difference(attemptDate).inDays;
      if (difference == 0 || difference == 1) {
        streak++;
        checkDate = attemptDate;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<Map<String, double>> getSubjectPerformance(
    int grade, {
    String? learnerProfileId,
  }) async {
    final db = await dbProvider.database;
    final clause = _learnerClause(learnerProfileId);
    final result = await db.rawQuery(
      'SELECT subject, SUM(correct_count) as c_count, SUM(total_questions) as t_count '
      'FROM quiz_attempts WHERE grade = ?$clause GROUP BY subject',
      [grade],
    );

    Map<String, double> perf = {};
    for (var row in result) {
      final subject = row['subject'] as String;
      final cCount = (row['c_count'] as num).toInt();
      final tCount = (row['t_count'] as num).toInt();
      perf[subject] = tCount > 0 ? (cCount / tCount) * 100 : 0.0;
    }
    return perf;
  }

  Future<List<ConceptDetail>> getWeakConceptsDetailed({
    int grade = 7,
    int limit = 5,
    String? learnerProfileId,
  }) async {
    final db = await dbProvider.database;
    final learnerJoin = learnerProfileId != null && learnerProfileId.isNotEmpty
        ? 'JOIN quiz_attempts qa ON a.attempt_id = qa.id AND qa.learner_profile_id = \'$learnerProfileId\''
        : '';
    final result = await db.rawQuery('''
      SELECT q.concept, q.subject, SUM(a.is_correct) as correct_num, COUNT(a.id) as total_num
      FROM attempt_answers a
      JOIN questions q ON a.question_id = q.id
      $learnerJoin
      WHERE q.grade = ?
      GROUP BY q.concept, q.subject
      HAVING total_num > 0 AND (CAST(correct_num AS FLOAT) / total_num) < 0.90
      ORDER BY (CAST(correct_num AS FLOAT) / total_num) ASC
      LIMIT ?
    ''', [grade, limit]);

    List<ConceptDetail> weak = [];
    for (var row in result) {
      final cNum = (row['correct_num'] as num).toInt();
      final tNum = (row['total_num'] as num).toInt();
      final pct = tNum > 0 ? (cNum / tNum) * 100 : 0.0;
      weak.add(ConceptDetail(
        concept: row['concept'] as String,
        subject: row['subject'] as String,
        correctCount: cNum,
        totalCount: tNum,
        accuracyPercentage: pct,
      ));
    }
    return weak;
  }

  Future<List<ConceptDetail>> getStrongConceptsDetailed({
    int grade = 7,
    int limit = 5,
    String? learnerProfileId,
  }) async {
    final db = await dbProvider.database;
    final learnerJoin = learnerProfileId != null && learnerProfileId.isNotEmpty
        ? 'JOIN quiz_attempts qa ON a.attempt_id = qa.id AND qa.learner_profile_id = \'$learnerProfileId\''
        : '';
    final result = await db.rawQuery('''
      SELECT q.concept, q.subject, SUM(a.is_correct) as correct_num, COUNT(a.id) as total_num
      FROM attempt_answers a
      JOIN questions q ON a.question_id = q.id
      $learnerJoin
      WHERE q.grade = ?
      GROUP BY q.concept, q.subject
      HAVING total_num > 0
      ORDER BY (CAST(correct_num AS FLOAT) / total_num) DESC
      LIMIT ?
    ''', [grade, limit]);

    List<ConceptDetail> strong = [];
    for (var row in result) {
      final cNum = (row['correct_num'] as num).toInt();
      final tNum = (row['total_num'] as num).toInt();
      final pct = tNum > 0 ? (cNum / tNum) * 100 : 0.0;
      strong.add(ConceptDetail(
        concept: row['concept'] as String,
        subject: row['subject'] as String,
        correctCount: cNum,
        totalCount: tNum,
        accuracyPercentage: pct,
      ));
    }
    return strong;
  }

  Future<List<String>> getWeakConcepts({
    int grade = 7,
    int limit = 5,
    String? learnerProfileId,
  }) async {
    final detailed = await getWeakConceptsDetailed(
      grade: grade,
      limit: limit,
      learnerProfileId: learnerProfileId,
    );
    return detailed.map((d) => d.concept).toList();
  }

  Future<List<String>> getStrongConcepts({
    int grade = 7,
    int limit = 5,
    String? learnerProfileId,
  }) async {
    final detailed = await getStrongConceptsDetailed(
      grade: grade,
      limit: limit,
      learnerProfileId: learnerProfileId,
    );
    return detailed.map((d) => d.concept).toList();
  }

  Future<Map<String, TopicUnitProgress>> getTopicProgressMap({
    required int grade,
    required String subject,
    String? learnerProfileId,
  }) async {
    final db = await dbProvider.database;
    String sql =
        'SELECT topic, SUM(correct_count) as c_count, SUM(total_questions) as t_count FROM quiz_attempts WHERE grade = ? AND subject = ?';
    List<dynamic> args = [grade, subject];

    if (learnerProfileId != null && learnerProfileId.isNotEmpty) {
      sql += ' AND learner_profile_id = ?';
      args.add(learnerProfileId);
    }
    sql += ' GROUP BY topic';

    final result = await db.rawQuery(sql, args);
    Map<String, TopicUnitProgress> map = {};

    for (var row in result) {
      final topic = row['topic'] as String;
      final cCount = (row['c_count'] as num).toInt();
      final tCount = (row['t_count'] as num).toInt();
      final pct = tCount > 0 ? (cCount / tCount) * 100 : 0.0;

      ProgressStatus status = ProgressStatus.notStarted;
      if (tCount > 0) {
        status = pct >= 65.0 ? ProgressStatus.completed : ProgressStatus.inProgress;
      }

      map[topic] = TopicUnitProgress(
        title: topic,
        totalQuestions: tCount,
        scorePercentage: pct,
        status: status,
      );
    }
    return map;
  }

  Future<Map<String, TopicUnitProgress>> getUnitProgressMap({
    required int grade,
    required String subject,
    required String topic,
    String? learnerProfileId,
  }) async {
    final db = await dbProvider.database;
    String sql = '''
      SELECT q.unit as unit_name, SUM(a.is_correct) as c_count, COUNT(a.id) as t_count
      FROM attempt_answers a
      JOIN questions q ON a.question_id = q.id
      JOIN quiz_attempts qa ON a.attempt_id = qa.id
      WHERE q.grade = ? AND q.subject = ? AND q.topic = ?
    ''';
    List<dynamic> args = [grade, subject, topic];

    if (learnerProfileId != null && learnerProfileId.isNotEmpty) {
      sql += ' AND qa.learner_profile_id = ?';
      args.add(learnerProfileId);
    }
    sql += ' GROUP BY q.unit';

    final result = await db.rawQuery(sql, args);
    Map<String, TopicUnitProgress> map = {};

    for (var row in result) {
      final unitName = row['unit_name'] as String? ?? topic;
      final cCount = (row['c_count'] as num).toInt();
      final tCount = (row['t_count'] as num).toInt();
      final pct = tCount > 0 ? (cCount / tCount) * 100 : 0.0;

      ProgressStatus status = ProgressStatus.notStarted;
      if (tCount > 0) {
        status = pct >= 65.0 ? ProgressStatus.completed : ProgressStatus.inProgress;
      }

      map[unitName] = TopicUnitProgress(
        title: unitName,
        totalQuestions: tCount,
        scorePercentage: pct,
        status: status,
      );
    }
    return map;
  }
}
