import 'local_database_service.dart';

/// Facade for backward-compatibility with existing LocalStorageService references.
/// Powered by Hive-backed LocalDatabaseService for persistent offline storage.
class LocalStorageService {
  static Future<void> init() async {
    await LocalDatabaseService.init();
  }

  static void saveString(String key, String value) {
    LocalDatabaseService.saveString(key, value);
  }

  static String? getString(String key) {
    return LocalDatabaseService.getString(key);
  }

  static void saveJson(String key, dynamic value) {
    LocalDatabaseService.saveJson(key, value);
  }

  static dynamic getJson(String key) {
    return LocalDatabaseService.getJson(key);
  }

  static void remove(String key) {
    LocalDatabaseService.remove(key);
  }

  static Future<void> clearAll() async {
    await LocalDatabaseService.clearAll();
  }
}
