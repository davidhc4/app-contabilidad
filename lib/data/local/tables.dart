import 'package:drift/drift.dart';

/// Tipo de transacción / categoría.
class TxType {
  TxType._();
  static const income = 'income';
  static const expense = 'expense';
}

/// Origen de la transacción: creada a mano o confirmada desde un SMS.
class TxSource {
  TxSource._();
  static const manual = 'manual';
  static const sms = 'sms';
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // income | expense
  TextColumn get icon => text()();
  TextColumn get color => text()(); // hex, ej. FF0A84FF
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // income | expense
  RealColumn get amount => real()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get rawSmsBody => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SmsBankSenders extends Table {
  TextColumn get id => text()();
  TextColumn get senderIdOrName => text()();
  TextColumn get regexPattern => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get themeMode =>
      text().withDefault(const Constant('dark'))(); // system | light | dark
  TextColumn get currencyCode => text().withDefault(const Constant('USD'))();
  BoolColumn get onboardingDone =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get smsDetectionEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
