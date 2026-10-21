import 'package:drift/drift.dart';

import '../local/database.dart';

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  /// Observa la fila única de configuración. Si por alguna condición de
  /// carrera (ej. primer arranque) todavía no existe, la crea con valores
  /// por defecto en vez de fallar.
  Stream<AppSetting> watch() {
    return (db.select(db.appSettings)..where((s) => s.id.equals(0)))
        .watch()
        .asyncMap((rows) async {
      if (rows.isNotEmpty) return rows.single;
      await db.into(db.appSettings).insertOnConflictUpdate(
            const AppSettingsCompanion(id: Value(0)),
          );
      return (db.select(db.appSettings)..where((s) => s.id.equals(0)))
          .getSingle();
    });
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

  /// Guarda el presupuesto mensual definido por el usuario. Pasa `null`
  /// para quitar el presupuesto configurado.
  Future<void> setMonthlyBudget(double? amount) {
    return (db.update(db.appSettings)..where((s) => s.id.equals(0))).write(
      AppSettingsCompanion(monthlyBudget: Value(amount)),
    );
  }
}
