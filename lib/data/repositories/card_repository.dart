import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

class CardRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  CardRepository(this.db);

  Stream<List<CardItem>> watchAll() {
    return (db.select(db.cards)
          ..where((c) => c.isArchived.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<String> addCard({
    required String name,
    required String lastFourDigits,
    required String network,
    required String colorStart,
    required String colorEnd,
  }) async {
    final id = _uuid.v4();
    await db.into(db.cards).insert(CardsCompanion.insert(
          id: id,
          name: name,
          lastFourDigits: lastFourDigits,
          network: network,
          colorStart: colorStart,
          colorEnd: colorEnd,
        ));
    return id;
  }

  Future<void> archive(String id) {
    return (db.update(db.cards)..where((c) => c.id.equals(id)))
        .write(const CardsCompanion(isArchived: Value(true)));
  }

  /// Edita los datos de una tarjeta existente.
  Future<void> updateCard({
    required String id,
    required String name,
    required String lastFourDigits,
    required String network,
    required String colorStart,
    required String colorEnd,
  }) {
    return (db.update(db.cards)..where((c) => c.id.equals(id))).write(
      CardsCompanion(
        name: Value(name),
        lastFourDigits: Value(lastFourDigits),
        network: Value(network),
        colorStart: Value(colorStart),
        colorEnd: Value(colorEnd),
      ),
    );
  }

  /// Elimina la tarjeta. Sus movimientos NO se borran: quedan como
  /// "sin tarjeta" para no perder el historial de gastos.
  Future<void> delete(String id) {
    return db.transaction(() async {
      await (db.update(db.transactions)..where((t) => t.cardId.equals(id)))
          .write(const TransactionsCompanion(cardId: Value<String?>(null)));
      await (db.delete(db.cards)..where((c) => c.id.equals(id))).go();
    });
  }
}
