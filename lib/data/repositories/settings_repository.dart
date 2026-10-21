import 'package:drift/drift.dart';

import '../local/database.dart';

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  Stream<AppSetting> watch() {
    return (db.select(db.appSettings)..where((s) => s.id.equals(0)))
        .watchSingle();
  }

  Future<void> setThemeMode(String mode) {
    return (db.update(db.appSettings)..where((s) => s.id.equals(0)))
        .write(AppSettingsCompanion(themeMode: Value(mode)));
  }

  Future<void> setSmsDetectionEnabled(bool enabled) {
    return (db.update(db.appSettings)..where((s) => s.id.equals(0)))
        .write(AppSettingsCompanion(smsDetectionEnabled: Value(enabled)));
  }

  Future<void> setOnboardingDone() {
    return (db.update(db.appSettings)..where((s) => s.id.equals(0)))
        .write(const AppSettingsCompanion(onboardingDone: Value(true)));
  }
}
