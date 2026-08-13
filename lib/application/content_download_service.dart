import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import 'api_service.dart';

enum DownloadStage { checkingVersion, preparing, downloading, unpacking, storing, done, error }

class ContentDownloadService {
  // ── Version tracking ────────────────────────────────────────────────────
  static const String _prefKeyVersion = 'content_version_';

  Future<String?> getLocalVersion(int gradeId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefKeyVersion$gradeId');
  }

  Future<void> _saveLocalVersion(int gradeId, String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefKeyVersion$gradeId', version);
  }

  // ── Main orchestrator ───────────────────────────────────────────────────
  Future<bool> syncGradeContent({
    required int gradeId,
    required void Function(DownloadStage) onStage,
    required void Function(double) onProgress,
    required void Function(String) onMessage,
  }) async {
    try {
      // 1. Check latest version from server
      onStage(DownloadStage.checkingVersion);
      onMessage('Checking for latest content...');

      final packageInfo = await ApiService.getLatestGradePackage(gradeId);
      if (packageInfo == null) {
        debugPrint('⚠️ [DEBUG] Could not reach server to fetch package info for Grade $gradeId');
        onMessage('Could not reach server. Using existing content.');
        onStage(DownloadStage.done);
        return false;
      }

      final serverVersion = packageInfo['version'] as String;
      final downloadUrl = packageInfo['downloadUrl'] as String;
      final localVersion = await getLocalVersion(gradeId);

      debugPrint('ℹ️ [DEBUG] Grade $gradeId - Local Version: $localVersion | Server Version: $serverVersion');
      debugPrint('ℹ️ [DEBUG] Download URL: $downloadUrl');

      if (localVersion == serverVersion && downloadUrl.isNotEmpty) {
        debugPrint('✅ [DEBUG] Content is up to date (v$serverVersion). Skipping download.');
        onMessage('Content is already up to date (v$serverVersion).');
        onStage(DownloadStage.done);
        return false;
      }

      if (downloadUrl.isEmpty) {
        debugPrint('⚠️ [DEBUG] Download URL is empty for Grade $gradeId.');
        onMessage('No downloadable content available for Grade $gradeId yet.');
        onStage(DownloadStage.done);
        return false;
      }

      // 2. Prepare to download
      onStage(DownloadStage.preparing);
      onMessage('Preparing to download Grade $gradeId content (v$serverVersion)...');
      await Future.delayed(const Duration(milliseconds: 400));

      // 3. Download with real progress
      onStage(DownloadStage.downloading);
      onMessage('Downloading content package...');

      final bytes = await ApiService.downloadPackage(
        url: downloadUrl,
        onProgress: onProgress,
      );

      if (bytes == null || bytes.isEmpty) {
        debugPrint('❌ [DEBUG] Downloaded bytes is null or empty!');
        onMessage('Download failed. Check your connection and try again.');
        onStage(DownloadStage.error);
        return false;
      }

      debugPrint('📦 [DEBUG] Download complete. Package size: ${bytes.length} bytes.');

      // 4. Unpack ZIP archive
      onStage(DownloadStage.unpacking);
      onMessage('Unpacking content archive...');
      onProgress(0.0);

      final archive = ZipDecoder().decodeBytes(bytes);

      final fileNames = archive.files.map((f) => f.name).toList();
      debugPrint('📂 [DEBUG] ZIP Archive File List: $fileNames');

      final dbFiles = archive.files
          .where((f) => f.isFile && (f.name.endsWith('.db') || f.name.endsWith('.sqlite')))
          .toList();
      final jsonFiles = archive.files
          .where((f) => f.isFile && f.name.endsWith('.json') && !f.name.endsWith('metadata.json'))
          .toList();

      onStage(DownloadStage.storing);
      final db = await AppDatabase.instance.database;
      int totalImported = 0;

      if (dbFiles.isNotEmpty) {
        // ── Case A: SQLite content.db in package ─────────────────────────────
        final dbFile = dbFiles.first;
        debugPrint('💾 [DEBUG] Found SQLite package DB: ${dbFile.name} (${dbFile.size} bytes)');

        final tempDir = await getTemporaryDirectory();
        final tempDbPath = '${tempDir.path}/temp_content_grade_$gradeId.db';
        final tempFile = File(tempDbPath);
        await tempFile.writeAsBytes(dbFile.content as List<int>);

        onMessage('Extracting questions from package database...');

        final packageDb = await openReadOnlyDatabase(tempDbPath);

        // Debug table count
        final tables = await packageDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
        debugPrint('📊 [DEBUG] Package DB Tables: ${tables.map((t) => t['name']).toList()}');

        final rawQCount = Sqflite.firstIntValue(await packageDb.rawQuery('SELECT COUNT(*) FROM questions')) ?? 0;
        debugPrint('📊 [DEBUG] Raw `questions` table count in package DB: $rawQCount');

        // Inspect available columns in packageDb to build query dynamically
        final pragmaCols = await packageDb.rawQuery("PRAGMA table_info(questions)");
        final colNames = pragmaCols.map((c) => c['name']?.toString()).toSet();

        final hasCompText = colNames.contains('comprehension_text');
        final hasImageUrl = colNames.contains('image_url');
        final hasImagePath = colNames.contains('image_path');
        final hasDiagramUrl = colNames.contains('diagram_url');
        final hasDiagramPath = colNames.contains('diagram_path');

        final compSql = hasCompText ? 'q.comprehension_text AS comprehension_text,' : "'' AS comprehension_text,";
        final imageSql = hasImageUrl ? 'q.image_url AS image_path,' : (hasImagePath ? 'q.image_path AS image_path,' : "'' AS image_path,");
        final diagramSql = hasDiagramUrl ? 'q.diagram_url AS diagram_path,' : (hasDiagramPath ? 'q.diagram_path AS diagram_path,' : "'' AS diagram_path,");

        // Fetch questions joined with taxonomy hierarchy (using LEFT JOINs to avoid dropping rows!)
        final List<Map<String, dynamic>> questionRows = await packageDb.rawQuery('''
          SELECT 
            q.id AS q_id,
            COALESCE(s.name, 'General') AS subject_name,
            COALESCE(t.name, 'General') AS topic_name,
            COALESCE(u.name, 'General Unit') AS unit_name,
            COALESCE(c.name, 'General Concept') AS concept_name,
            COALESCE(q.difficulty, 'Medium') AS difficulty,
            q.question_text AS question_text,
            $compSql
            $imageSql
            $diagramSql
            COALESCE(q.explanation, '') AS explanation
          FROM questions q
          LEFT JOIN concepts c ON q.concept_id = c.id
          LEFT JOIN units u ON c.unit_id = u.id
          LEFT JOIN topics t ON u.topic_id = t.id
          LEFT JOIN subjects s ON t.subject_id = s.id
        ''');

        debugPrint('📊 [DEBUG] Joined Question rows count: ${questionRows.length}');

        // Fetch answer options
        final List<Map<String, dynamic>> optionRows = await packageDb.rawQuery('''
          SELECT id, question_id, option_text, is_correct FROM answer_options
        ''');

        debugPrint('📊 [DEBUG] Answer Options count in package DB: ${optionRows.length}');

        await packageDb.close();
        try { await tempFile.delete(); } catch (_) {}

        // Group options by question_id
        final Map<String, List<Map<String, dynamic>>> optionsByQ = {};
        for (final opt in optionRows) {
          final qId = opt['question_id']?.toString() ?? '';
          optionsByQ.putIfAbsent(qId, () => []).add(opt);
        }

        // ── PRINT FIRST QUESTION FOR DEBUGGING ──────────────────────────────
        if (questionRows.isNotEmpty) {
          final firstQ = questionRows.first;
          final firstOpts = optionsByQ[firstQ['q_id']?.toString()] ?? [];
          debugPrint('====================================================');
          debugPrint('🎯 [DEBUG] FIRST DOWNLOADED QUESTION DETAILS:');
          debugPrint('   ID: ${firstQ['q_id']}');
          debugPrint('   Subject: ${firstQ['subject_name']}');
          debugPrint('   Topic: ${firstQ['topic_name']}');
          debugPrint('   Unit: ${firstQ['unit_name']}');
          debugPrint('   Concept: ${firstQ['concept_name']}');
          debugPrint('   Difficulty: ${firstQ['difficulty']}');
          debugPrint('   Text: "${firstQ['question_text']}"');
          if (firstQ['comprehension_text'] != null) {
            debugPrint('   Comprehension Text: "${firstQ['comprehension_text']}"');
          }
          debugPrint('   Explanation: "${firstQ['explanation']}"');
          debugPrint('   Options (${firstOpts.length}):');
          for (var opt in firstOpts) {
            debugPrint('     - ${opt['option_text']} (Correct: ${opt['is_correct']})');
          }
          debugPrint('====================================================');
        } else {
          debugPrint('⚠️ [DEBUG] NO QUESTIONS WERE FOUND IN PACKAGE DB!');
        }

        // Delete existing questions & options for this grade in grame_one.db
        onMessage('Clearing old Grade $gradeId content...');
        await db.transaction((txn) async {
          final existingRows = await txn.rawQuery('SELECT id FROM questions WHERE grade = ?', [gradeId]);
          debugPrint('🗑️ [DEBUG] Purging ${existingRows.length} existing Grade $gradeId questions from local DB...');
          for (final row in existingRows) {
            final qId = row['id'] as String;
            await txn.delete('options', where: 'question_id = ?', whereArgs: [qId]);
          }
          await txn.delete('questions', where: 'grade = ?', whereArgs: [gradeId]);
        });

        onMessage('Importing ${questionRows.length} questions into local database...');

        // Insert new questions & options
        await db.transaction((txn) async {
          for (int i = 0; i < questionRows.length; i++) {
            final q = questionRows[i];
            final qId = q['q_id']?.toString() ?? 'pkg_${gradeId}_$i';

            await txn.insert('questions', {
              'id': qId,
              'grade': gradeId,
              'subject': q['subject_name'] ?? '',
              'topic': q['topic_name'] ?? '',
              'unit': q['unit_name'] ?? '',
              'concept': q['concept_name'] ?? '',
              'difficulty': q['difficulty'] ?? 'Medium',
              'question_text': q['question_text'] ?? '',
              'comprehension_text': q['comprehension_text'],
              'image_path': q['image_path'],
              'diagram_path': q['diagram_path'],
              'explanation': q['explanation'] ?? '',
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            final opts = optionsByQ[q['q_id']?.toString()] ?? [];
            for (final opt in opts) {
              await txn.insert('options', {
                'id': opt['id']?.toString() ?? '${qId}_${opt['option_text']}',
                'question_id': qId,
                'option_text': opt['option_text'] ?? '',
                'is_correct': (opt['is_correct'] == 1 || opt['is_correct'] == true) ? 1 : 0,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }

            totalImported++;
            onProgress((i + 1) / questionRows.length);
          }
        });

        debugPrint('✅ [DEBUG] Successfully imported $totalImported downloaded questions for Grade $gradeId into local SQLite database!');

      } else if (jsonFiles.isNotEmpty) {
        // ── Case B: JSON content files ────────────────────────────────────────
        debugPrint('📄 [DEBUG] Found ${jsonFiles.length} JSON content file(s) in package.');
        onMessage('Clearing old Grade $gradeId content...');
        await db.transaction((txn) async {
          final existingRows = await txn.rawQuery('SELECT id FROM questions WHERE grade = ?', [gradeId]);
          for (final row in existingRows) {
            final qId = row['id'] as String;
            await txn.delete('options', where: 'question_id = ?', whereArgs: [qId]);
          }
          await txn.delete('questions', where: 'grade = ?', whereArgs: [gradeId]);
        });

        onMessage('Importing questions into local database...');

        int fileIdx = 0;
        for (final file in jsonFiles) {
          fileIdx++;
          onProgress(fileIdx / jsonFiles.length);

          final jsonStr = utf8.decode(file.content as List<int>);
          final data = jsonDecode(jsonStr);

          List questions = [];
          if (data is Map && data.containsKey('questions')) {
            questions = data['questions'] as List;
          } else if (data is List) {
            questions = data;
          }

          debugPrint('📄 [DEBUG] JSON file "${file.name}" contained ${questions.length} questions.');

          if (questions.isNotEmpty && totalImported == 0) {
            final firstQ = questions.first as Map<String, dynamic>;
            debugPrint('====================================================');
            debugPrint('🎯 [DEBUG] FIRST DOWNLOADED JSON QUESTION:');
            debugPrint('   Text: "${firstQ['questionText'] ?? firstQ['question_text']}"');
            debugPrint('====================================================');
          }

          await db.transaction((txn) async {
            for (final q in questions) {
              final qMap = q as Map<String, dynamic>;
              final qId = qMap['id']?.toString() ?? '';
              if (qId.isEmpty) continue;

              await txn.insert(
                'questions',
                {
                  'id': qId,
                  'grade': qMap['grade'] ?? gradeId,
                  'subject': qMap['subject'] ?? '',
                  'topic': qMap['topic'] ?? '',
                  'unit': qMap['unit'] ?? '',
                  'concept': qMap['concept'] ?? '',
                  'difficulty': qMap['difficulty'] ?? 'Medium',
                  'question_text': qMap['questionText'] ?? qMap['question_text'] ?? '',
                  'image_path': qMap['imagePath'] ?? qMap['image_path'],
                  'explanation': qMap['explanation'] ?? '',
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              await txn.delete('options', where: 'question_id = ?', whereArgs: [qId]);
              final options = (qMap['options'] as List?) ?? (qMap['answerOptions'] as List?) ?? [];
              for (final opt in options) {
                final o = opt as Map<String, dynamic>;
                await txn.insert('options', {
                  'id': o['id']?.toString() ?? '${qId}_${o['optionText']}',
                  'question_id': qId,
                  'option_text': o['optionText'] ?? o['option_text'] ?? '',
                  'is_correct': (o['isCorrect'] == true || o['is_correct'] == 1) ? 1 : 0,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }

              totalImported++;
            }
          });
        }
      } else {
        debugPrint('❌ [DEBUG] ZIP package contained neither .db nor .json content files!');
        onMessage('Package format error: no database or JSON content found.');
        onStage(DownloadStage.error);
        return false;
      }

      await _saveLocalVersion(gradeId, serverVersion);

      // Verify question count after import
      final finalCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM questions WHERE grade = ?', [gradeId])) ?? 0;
      debugPrint('🎉 [DEBUG] FINAL SQLite Question count in grame_one.db for Grade $gradeId: $finalCount');

      onStage(DownloadStage.done);
      onMessage('Done! $totalImported questions loaded for Grade $gradeId.');
      return true;
    } catch (e, stack) {
      debugPrint('💥 [DEBUG] Exception in syncGradeContent: $e');
      debugPrint('   Stack trace: $stack');
      onMessage('Download or sync failed. Please check connection and try again.');
      onStage(DownloadStage.error);
      return false;
    }
  }
}
