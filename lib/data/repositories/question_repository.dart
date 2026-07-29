import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/models.dart';

class QuestionRepository {
  final AppDatabase dbProvider;

  QuestionRepository({AppDatabase? dbProvider})
      : dbProvider = dbProvider ?? AppDatabase.instance;

  Future<void> insertQuestions(List<Question> questions) async {
    final db = await dbProvider.database;
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
  }

  Future<List<Question>> getQuestions({
    required int grade,
    String? subject,
    String? topic,
    String? indigenousLanguage,
    int? limit,
  }) async {
    final db = await dbProvider.database;
    String whereClause = 'grade = ?';
    List<dynamic> whereArgs = [grade];

    if (subject != null && subject.isNotEmpty) {
      whereClause += ' AND subject = ?';
      whereArgs.add(subject);
    }
    if (topic != null && topic.isNotEmpty) {
      whereClause += ' AND topic = ?';
      whereArgs.add(topic);
    }
    // Indigenous language filtering:
    //  - When subject == 'Indigenous Language': restrict to the chosen language unit only.
    //  - When subject == null (all-subjects query such as daily challenge / revision):
    //      keep every non-indigenous question AND include only the chosen language's
    //      indigenous questions – exclude all other languages' questions.
    if (indigenousLanguage != null && indigenousLanguage.isNotEmpty) {
      if (subject == 'Indigenous Language') {
        // Topic-level practice: show only this language's questions.
        whereClause += ' AND unit = ?';
        whereArgs.add(indigenousLanguage);
      } else if (subject == null) {
        // Cross-subject query: keep non-indigenous rows + chosen language indigenous rows.
        whereClause += " AND (subject != 'Indigenous Language' OR unit = ?)";
        whereArgs.add(indigenousLanguage);
      }
      // If subject is something other than Indigenous Language (e.g. 'Science'),
      // don't add a unit filter at all – those subjects use unit for their own categories.
    }

    final List<Map<String, dynamic>> questionMaps = await db.query(
      'questions',
      where: whereClause,
      whereArgs: whereArgs,
      limit: limit,
    );

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
  }) async {
    final db = await dbProvider.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT topic FROM questions WHERE grade = ? AND subject = ?',
      [grade, subject],
    );
    return result.map((r) => r['topic'] as String).toList();
  }

  Future<int> getQuestionCount({required int grade}) async {
    final db = await dbProvider.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions WHERE grade = ?', [grade]),
    );
    return count ?? 0;
  }

  /// Deletes all questions (and their options) for [grade].
  /// Called by ContentManager before a re-seed to avoid duplicate-key errors.
  Future<void> deleteAllQuestions({required int grade}) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      // Fetch all question IDs for this grade so we can delete options too.
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

