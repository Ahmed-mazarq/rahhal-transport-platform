import '../models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings?> getSettings(String userId);
  Future<void> updateSettings(String userId, AppSettings settings);
  Future<void> clearCache();
  Stream<AppSettings?> watchSettings(String userId);
  AppSettings? getCachedSettings();
}
