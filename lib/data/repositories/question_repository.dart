import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/models.dart';

class QuestionRepository {
  final AppDatabase dbProvider;

  QuestionRepository({AppDatabase? dbProvider})
      : dbProvider = dbProvider ?? AppDatabase.instance;

  /// Helper to build flexible subject SQL conditions so variations like 'Shona', 'ChiShona',
  /// 'Mathematics', 'Maths', 'Agriculture, Science and Technology and ICT', 'Science', etc.
  /// are all matched seamlessly.
  static String _buildSubjectCondition(String subject, List<dynamic> whereArgs, {String? indigenousLanguage}) {
    final s = subject.toLowerCase().trim();

    if (s.contains('math')) {
      whereArgs.add('%math%');
      return 'LOWER(subject) LIKE ?';
    } else if (s.contains('english')) {
      whereArgs.add('%english%');
      return 'LOWER(subject) LIKE ?';
    } else if (s.contains('social')) {
      whereArgs.add('%social%');
      return 'LOWER(subject) LIKE ?';
    } else if (s.contains('physic') || s.contains('art') || s.contains('pe') || s.contains('sport')) {
      whereArgs.add('%physic%');
      whereArgs.add('%art%');
      whereArgs.add('%pe%');
      whereArgs.add('%sport%');
      return '(LOWER(subject) LIKE ? OR LOWER(subject) LIKE ? OR LOWER(subject) LIKE ? OR LOWER(subject) LIKE ?)';
    } else if (s.contains('agri') || s.contains('sci') || s.contains('ict') || s.contains('tech')) {
      whereArgs.add('%agri%');
      whereArgs.add('%sci%');
      whereArgs.add('%ict%');
      whereArgs.add('%tech%');
      return '(LOWER(subject) LIKE ? OR LOWER(subject) LIKE ? OR LOWER(subject) LIKE ? OR LOWER(subject) LIKE ?)';
    } else if (s.contains('indigenous') || s.contains('shona') || s.contains('ndebele') || s.contains('language') || s.contains('tonga') || s.contains('kalanga') || s.contains('venda') || s.contains('tshivenda') || s.contains('nambya') || s.contains('sesotho') || s.contains('xichangana') || s.contains('chishona') || s.contains('isindebele')) {
      if (indigenousLanguage != null && indigenousLanguage.isNotEmpty) {
        final lang = indigenousLanguage.toLowerCase().trim();
        if (lang.contains('ndebele') || lang.contains('isindebele')) {
          whereArgs.add('%ndebele%');
          whereArgs.add('%isindebele%');
          whereArgs.add('%ndebele%');
          whereArgs.add('%isindebele%');
          whereArgs.add('%ndebele%');
          whereArgs.add('%isindebele%');
          whereArgs.add('%ndebele%');
          whereArgs.add('%isindebele%');
          return '(LOWER(subject) LIKE ? OR LOWER(subject) LIKE ? OR LOWER(unit) LIKE ? OR LOWER(unit) LIKE ? OR LOWER(topic) LIKE ? OR LOWER(topic) LIKE ? OR LOWER(concept) LIKE ? OR LOWER(concept) LIKE ?)';
        } else if (lang.contains('shona') || lang.contains('chishona')) {
          whereArgs.add('%shona%');
          whereArgs.add('%chishona%');
          whereArgs.add('%shona%');
          whereArgs.add('%chishona%');
          whereArgs.add('%shona%');
          whereArgs.add('%chishona%');
          whereArgs.add('%shona%');
          whereArgs.add('%chishona%');
          whereArgs.add('%indigenous%');
          whereArgs.add('%ndebele%');
          whereArgs.add('%tonga%');
          return '(LOWER(subject) LIKE ? OR LOWER(subject) LIKE ? OR LOWER(unit) LIKE ? OR LOWER(unit) LIKE ? OR LOWER(topic) LIKE ? OR LOWER(topic) LIKE ? OR LOWER(concept) LIKE ? OR LOWER(concept) LIKE ? OR (LOWER(subject) LIKE ? AND LOWER(topic) NOT LIKE ? AND LOWER(topic) NOT LIKE ?))';
        } else {
          whereArgs.add('%$lang%');
          whereArgs.add('%$lang%');
          whereArgs.add('%$lang%');
          whereArgs.add('%$lang%');
          return '(LOWER(subject) LIKE ? OR LOWER(unit) LIKE ? OR LOWER(topic) LIKE ? OR LOWER(concept) LIKE ?)';
        }
      } else {
        whereArgs.add('%indigenous%');
        whereArgs.add('%shona%');
        whereArgs.add('%ndebele%');
        return '(LOWER(subject) LIKE ? OR LOWER(subject) LIKE ? OR LOWER(subject) LIKE ?)';
      }
    } else {
      whereArgs.add(subject);
      return 'subject = ?';
    }
  }

  Future<void> insertQuestions(List<Question> questions) async {
    final db = await dbProvider.database;
    debugPrint('💾 QuestionRepository.insertQuestions: Inserting ${questions.length} questions...');
    await db.transaction((txn) async {
      for (var q in questions) {
        await txn.insert(
          'questions',
          q.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (var opt in q.options) {
          await txn.insert(
            'options',
            opt.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
    debugPrint('✅ QuestionRepository.insertQuestions: Done.');
  }

  Future<List<Question>> getQuestions({
    required int grade,
    String? subject,
    String? topic,
    String? unit,
    String? indigenousLanguage,
    int? limit,
  }) async {
    final db = await dbProvider.database;
    String whereClause = 'grade = ?';
    List<dynamic> whereArgs = [grade];

    if (subject != null && subject.isNotEmpty) {
      final subCond = _buildSubjectCondition(subject, whereArgs, indigenousLanguage: indigenousLanguage);
      whereClause += ' AND $subCond';
    }
    if (topic != null && topic.isNotEmpty) {
      whereClause += ' AND topic = ?';
      whereArgs.add(topic);
    }
    if (unit != null && unit.isNotEmpty) {
      whereClause += ' AND unit = ?';
      whereArgs.add(unit);
    }

    debugPrint('🔍 getQuestions SQL: $whereClause | Args: $whereArgs');
    final List<Map<String, dynamic>> questionMaps = await db.query(
      'questions',
      where: whereClause,
      whereArgs: whereArgs,
      limit: limit,
    );
    debugPrint('🔍 getQuestions returned ${questionMaps.length} rows');

    List<Question> questions = [];
    for (var qMap in questionMaps) {
      final String qId = qMap['id'] as String;
      final List<Map<String, dynamic>> optionMaps = await db.query(
        'options',
        where: 'question_id = ?',
        whereArgs: [qId],
      );
      final options = optionMaps.map((o) => QuestionOption.fromMap(o)).toList();
      questions.add(Question.fromMap(qMap, options));
    }
    return questions;
  }

  Future<List<String>> getTopicsForSubject({
    required int grade,
    required String subject,
    String? indigenousLanguage,
  }) async {
    final db = await dbProvider.database;
    List<dynamic> whereArgs = [grade];
    final subCond = _buildSubjectCondition(subject, whereArgs, indigenousLanguage: indigenousLanguage);

    final String sql = 'SELECT DISTINCT topic FROM questions WHERE grade = ? AND $subCond AND topic IS NOT NULL AND topic != "" ORDER BY topic ASC';
    debugPrint('🔍 getTopicsForSubject SQL: $sql | Args: $whereArgs');

    final List<Map<String, dynamic>> result = await db.rawQuery(sql, whereArgs);
    final topics = result.map((r) => r['topic'] as String).toList();
    debugPrint('🔍 getTopicsForSubject returned ${topics.length} topics: $topics');
    return topics;
  }

  Future<List<String>> getUnitsForTopic({
    required int grade,
    required String subject,
    required String topic,
    String? indigenousLanguage,
  }) async {
    final db = await dbProvider.database;
    List<dynamic> whereArgs = [grade];
    final subCond = _buildSubjectCondition(subject, whereArgs, indigenousLanguage: indigenousLanguage);
    whereArgs.add(topic);

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT unit FROM questions WHERE grade = ? AND $subCond AND topic = ? AND unit IS NOT NULL AND unit != "" ORDER BY unit ASC',
      whereArgs,
    );
    return result.map((r) => r['topic'] as String? ?? r['unit'] as String).toList();
  }

  Future<int> getQuestionCount({required int grade}) async {
    final db = await dbProvider.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions WHERE grade = ?', [grade]),
    );
    return count ?? 0;
  }

  Future<int> getQuestionCountForSubject({
    required int grade,
    required String subject,
    String? indigenousLanguage,
  }) async {
    final db = await dbProvider.database;
    List<dynamic> whereArgs = [grade];
    final subCond = _buildSubjectCondition(subject, whereArgs, indigenousLanguage: indigenousLanguage);
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions WHERE grade = ? AND $subCond', whereArgs),
    );
    return count ?? 0;
  }

  Future<int> getQuestionCountForUnit({
    required int grade,
    required String subject,
    required String topic,
    String? unit,
    String? indigenousLanguage,
  }) async {
    final db = await dbProvider.database;
    List<dynamic> whereArgs = [grade];
    final subCond = _buildSubjectCondition(subject, whereArgs, indigenousLanguage: indigenousLanguage);
    whereArgs.add(topic);

    String sql = 'SELECT COUNT(*) FROM questions WHERE grade = ? AND $subCond AND topic = ?';
    if (unit != null && unit.isNotEmpty) {
      sql += ' AND unit = ?';
      whereArgs.add(unit);
    }
    final count = Sqflite.firstIntValue(await db.rawQuery(sql, whereArgs));
    return count ?? 0;
  }

  /// Deletes all questions (and their options) for [grade].
  Future<void> deleteAllQuestions({required int grade}) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT id FROM questions WHERE grade = ?',
        [grade],
      );
      for (final row in rows) {
        final id = row['id'] as String;
        await txn.delete('options', where: 'question_id = ?', whereArgs: [id]);
      }
      await txn.delete('questions', where: 'grade = ?', whereArgs: [grade]);
    });
  }
}
