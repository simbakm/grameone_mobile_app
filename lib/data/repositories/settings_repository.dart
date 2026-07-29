import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/models.dart';

class SettingsRepository {
  final AppDatabase dbProvider;

  SettingsRepository({AppDatabase? dbProvider})
      : dbProvider = dbProvider ?? AppDatabase.instance;

  Future<UserSettings> getSettings() async {
    final db = await dbProvider.database;
    final maps = await db.query('user_settings', where: 'id = 1');
    if (maps.isNotEmpty) {
      return UserSettings.fromMap(maps.first);
    }
    final defaultSettings = UserSettings(
      selectedGrade: 7,
      selectedIndigenousLang: 'Shona',
      darkMode: false,
    );
    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  Future<void> saveSettings(UserSettings settings) async {
    final db = await dbProvider.database;
    await db.insert(
      'user_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGrade(int grade) async {
    final db = await dbProvider.database;
    await db.update(
      'user_settings',
      {'selected_grade': grade},
      where: 'id = 1',
    );
  }

  Future<void> updateIndigenousLanguage(String language) async {
    final db = await dbProvider.database;
    await db.update(
      'user_settings',
      {'selected_indigenous_lang': language},
      where: 'id = 1',
    );
  }
}
