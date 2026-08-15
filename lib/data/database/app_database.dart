import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported for offline SQLite database.');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory docDir = await getApplicationDocumentsDirectory();
    final String path = join(docDir.path, 'grame_one.db');

    return await openDatabase(
      path,
      version: 5,          // ← bumped to version 5 for per-learner badges
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Questions Table
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        grade INTEGER NOT NULL,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        unit TEXT NOT NULL,
        concept TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        question_text TEXT NOT NULL,
        comprehension_text TEXT,
        image_path TEXT,
        diagram_path TEXT,
        explanation TEXT NOT NULL
      )
    ''');

    // Options Table
    await db.execute('''
      CREATE TABLE options (
        id TEXT PRIMARY KEY,
        question_id TEXT NOT NULL,
        option_text TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
      )
    ''');

    // Quiz Attempts Table
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id TEXT PRIMARY KEY,
        test_type TEXT NOT NULL,
        grade INTEGER NOT NULL,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        learner_profile_id TEXT
      )
    ''');

    // Attempt Answers Table
    await db.execute('''
      CREATE TABLE attempt_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        selected_option_id TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        FOREIGN KEY (attempt_id) REFERENCES quiz_attempts (id) ON DELETE CASCADE
      )
    ''');

    // License Info Table (Global fallback)
    await db.execute('''
      CREATE TABLE license_info (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        device_id TEXT NOT NULL,
        activation_code TEXT,
        is_activated INTEGER NOT NULL DEFAULT 0,
        activated_at TEXT,
        expiry_date TEXT,
        last_opened_date TEXT NOT NULL
      )
    ''');

    // User Settings Table
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        selected_grade INTEGER NOT NULL DEFAULT 7,
        selected_indigenous_lang TEXT NOT NULL DEFAULT 'Shona',
        dark_mode INTEGER NOT NULL DEFAULT 0,
        is_grade_locked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Badges Table (per learner)
    await db.execute('''
      CREATE TABLE badges (
        id TEXT PRIMARY KEY,
        badge_key TEXT NOT NULL,
        learner_profile_id TEXT NOT NULL DEFAULT 'global',
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        unlocked_at TEXT,
        UNIQUE(badge_key, learner_profile_id)
      )
    ''');

    // ── v4: Learner Profiles Table with Per-Learner License & Lock ─────
    await db.execute('''
      CREATE TABLE learner_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT NOT NULL DEFAULT '🧒',
        grade INTEGER NOT NULL DEFAULT 7,
        indigenous_language TEXT NOT NULL DEFAULT 'Shona',
        created_at TEXT NOT NULL,
        activation_code TEXT,
        expiry_date TEXT,
        is_activated INTEGER NOT NULL DEFAULT 0,
        is_grade_locked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Active Profile Preference ─────────────────────────────────
    await db.execute('''
      CREATE TABLE active_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        learner_profile_id TEXT
      )
    ''');

    // Initial Default Records
    await db.insert('user_settings', {
      'id': 1,
      'selected_grade': 7,
      'selected_indigenous_lang': 'Shona',
      'dark_mode': 0,
      'is_grade_locked': 0,
    });
  }

  /// Migration from version 1 → 4: add learner_profiles, active_profile,
  /// per-learner license and grade lock columns.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE quiz_attempts ADD COLUMN learner_profile_id TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS learner_profiles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          avatar TEXT NOT NULL DEFAULT '🧒',
          grade INTEGER NOT NULL DEFAULT 7,
          indigenous_language TEXT NOT NULL DEFAULT 'Shona',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS active_profile (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          learner_profile_id TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE user_settings ADD COLUMN is_grade_locked INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        debugPrint('Column is_grade_locked may already exist: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE learner_profiles ADD COLUMN activation_code TEXT');
        await db.execute('ALTER TABLE learner_profiles ADD COLUMN expiry_date TEXT');
        await db.execute('ALTER TABLE learner_profiles ADD COLUMN is_activated INTEGER NOT NULL DEFAULT 0');
        await db.execute('ALTER TABLE learner_profiles ADD COLUMN is_grade_locked INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        debugPrint('Per-learner license columns may already exist: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE badges RENAME TO badges_old');
        await db.execute('''
          CREATE TABLE badges (
            id TEXT PRIMARY KEY,
            badge_key TEXT NOT NULL,
            learner_profile_id TEXT NOT NULL DEFAULT 'global',
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            icon_name TEXT NOT NULL,
            unlocked_at TEXT,
            UNIQUE(badge_key, learner_profile_id)
          )
        ''');
        await db.execute('''
          INSERT OR IGNORE INTO badges (id, badge_key, learner_profile_id, title, description, icon_name, unlocked_at)
          SELECT id, badge_key, 'global', title, description, icon_name, unlocked_at FROM badges_old
        ''');
        await db.execute('DROP TABLE IF EXISTS badges_old');
      } catch (e) {
        debugPrint('Badge v5 migration: e');
      }
    }
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('questions');
    await db.delete('options');
    await db.delete('quiz_attempts');
    await db.delete('attempt_answers');
    await db.delete('badges');
  }
}
