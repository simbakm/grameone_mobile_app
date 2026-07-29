import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/models.dart';

class LicenseRepository {
  final AppDatabase dbProvider;

  LicenseRepository({AppDatabase? dbProvider})
      : dbProvider = dbProvider ?? AppDatabase.instance;

  Future<LicenseInfo?> getLicenseInfo() async {
    final db = await dbProvider.database;
    final maps = await db.query('license_info', where: 'id = 1');
    if (maps.isNotEmpty) {
      return LicenseInfo.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveLicenseInfo(LicenseInfo info) async {
    final db = await dbProvider.database;
    await db.insert(
      'license_info',
      info.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLastOpenedDate(DateTime date) async {
    final db = await dbProvider.database;
    await db.update(
      'license_info',
      {'last_opened_date': date.toIso8601String()},
      where: 'id = 1',
    );
  }
}
