import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

class SmsSenderRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  SmsSenderRepository(this.db);

  Stream<List<SmsBankSender>> watchAll() {
    return db.select(db.smsBankSenders).watch();
  }

  Future<List<SmsBankSender>> enabled() {
    return (db.select(db.smsBankSenders)
          ..where((s) => s.isEnabled.equals(true)))
        .get();
  }

  Future<void> add({
    required String senderIdOrName,
    required String regexPattern,
  }) {
    return db.into(db.smsBankSenders).insert(SmsBankSendersCompanion.insert(
          id: _uuid.v4(),
          senderIdOrName: senderIdOrName,
          regexPattern: regexPattern,
        ));
  }

  Future<void> setEnabled(String id, bool enabled) {
    return (db.update(db.smsBankSenders)..where((s) => s.id.equals(id)))
        .write(SmsBankSendersCompanion(isEnabled: Value(enabled)));
  }

  Future<void> delete(String id) {
    return (db.delete(db.smsBankSenders)..where((s) => s.id.equals(id))).go();
  }
}
