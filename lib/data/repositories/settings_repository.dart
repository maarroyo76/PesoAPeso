import '../local/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<String?> get(String key) => _db.getSetting(key);
  Future<void> set(String key, String value) => _db.setSetting(key, value);
}
