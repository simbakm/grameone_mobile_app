import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/models.dart';

class LearnerRepository {
  final AppDatabase appDatabase;

  LearnerRepository({AppDatabase? appDatabase})
      : appDatabase = appDatabase ?? AppDatabase.instance;

  Future<List<LearnerProfile>> getLearnerProfiles() async {
    final db = await appDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('learner_profiles', orderBy: 'created_at ASC');
    return maps.map((map) => LearnerProfile.fromMap(map)).toList();
  }

  Future<LearnerProfile?> getActiveLearnerProfile() async {
    final db = await appDatabase.database;
    final List<Map<String, dynamic>> activeMaps = await db.query('active_profile', where: 'id = 1');
    if (activeMaps.isNotEmpty) {
      final activeId = activeMaps.first['learner_profile_id'] as String?;
      if (activeId != null) {
        final List<Map<String, dynamic>> profileMaps = await db.query(
          'learner_profiles',
          where: 'id = ?',
          whereArgs: [activeId],
        );
        if (profileMaps.isNotEmpty) {
          return LearnerProfile.fromMap(profileMaps.first);
        }
      }
    }

    // Default: return first profile if exists
    final profiles = await getLearnerProfiles();
    if (profiles.isNotEmpty) {
      return profiles.first;
    }
    return null;
  }

  Future<void> setActiveLearnerProfileId(String profileId) async {
    final db = await appDatabase.database;
    await db.insert(
      'active_profile',
      {'id': 1, 'learner_profile_id': profileId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LearnerProfile> saveLearnerProfile(LearnerProfile profile) async {
    final db = await appDatabase.database;
    await db.insert(
      'learner_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return profile;
  }

  Future<void> updateLearnerProfile(LearnerProfile profile) async {
    final db = await appDatabase.database;
    await db.update(
      'learner_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> deleteLearnerProfile(String profileId) async {
    final db = await appDatabase.database;
    await db.delete('learner_profiles', where: 'id = ?', whereArgs: [profileId]);
    await db.delete('quiz_attempts', where: 'learner_profile_id = ?', whereArgs: [profileId]);
  }
}
