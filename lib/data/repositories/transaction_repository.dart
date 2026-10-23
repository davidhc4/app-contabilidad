import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/tables.dart';

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;
  TransactionWithCategory(this.transaction, this.category);
}

class MonthSummary {
  final double income;
  final double expense;
  double get net => income - expense;
  MonthSummary({required this.income, required this.expense});
}

class CategoryTotal {
  final Category category;
  final double total;
  CategoryTotal(this.category, this.total);
}

class TransactionRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  TransactionRepository(this.db);

  Stream<List<TransactionWithCategory>> watchAll() {
    final query = db.select(db.transactions).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.transactions.categoryId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(db.transactions.date)]);

    return query.watch().map((rows) => rows
        .map((row) => TransactionWithCategory(
              row.readTable(db.transactions),
              row.readTable(db.categories),
            ))
        .toList());
  }

  Stream<List<TransactionWithCategory>> watchInRange(
      DateTime start, DateTime end) {
    final query = db.select(db.transactions).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.transactions.categoryId),
      ),
    ])
      ..where(db.transactions.date.isBiggerOrEqualValue(start) &
          db.transactions.date.isSmallerThanValue(end))
      ..orderBy([OrderingTerm.desc(db.transactions.date)]);

    return query.watch().map((rows) => rows
        .map((row) => TransactionWithCategory(
              row.readTable(db.transactions),
              row.readTable(db.categories),
            ))
        .toList());
  }

  /// Transacciones asociadas a una tarjeta específica (para la pantalla de
  /// detalle de la tarjeta).
  Stream<List<TransactionWithCategory>> watchByCard(String cardId) {
    final query = db.select(db.transactions).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.transactions.categoryId),
      ),
    ])
      ..where(db.transactions.cardId.equals(cardId))
      ..orderBy([OrderingTerm.desc(db.transactions.date)]);

    return query.watch().map((rows) => rows
        .map((row) => TransactionWithCategory(
              row.readTable(db.transactions),
              row.readTable(db.categories),
            ))
        .toList());
  }

  Stream<MonthSummary> watchMonthSummary(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return watchInRange(start, end).map((items) {
      double income = 0, expense = 0;
      for (final item in items) {
        if (item.transaction.type == TxType.income) {
          income += item.transaction.amount;
        } else if (item.transaction.type == TxType.expense) {
          expense += item.transaction.amount;
        }
      }
      return MonthSummary(income: income, expense: expense);
    });
  }

  Stream<List<CategoryTotal>> watchExpenseByCategory(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return watchInRange(start, end).map((items) {
      final totals = <String, double>{};
      final cats = <String, Category>{};
      for (final item in items) {
        if (item.transaction.type != TxType.expense) continue;
        totals.update(item.category.id, (v) => v + item.transaction.amount,
            ifAbsent: () => item.transaction.amount);
        cats[item.category.id] = item.category;
      }
      final result = totals.entries
          .map((e) => CategoryTotal(cats[e.key]!, e.value))
          .toList();
      result.sort((a, b) => b.total.compareTo(a.total));
      return result;
    });
  }

  Future<void> add({
    String? id,
    required String type,
    required double amount,
    required String categoryId,
    String description = '',
    required DateTime date,
    String source = TxSource.manual,
    String? rawSmsBody,
    String? cardId,
  }) {
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: id ?? _uuid.v4(),
          type: type,
          amount: amount,
          categoryId: categoryId,
          description: Value(description),
          date: date,
          source: Value(source),
          rawSmsBody: Value(rawSmsBody),
          cardId: Value(cardId),
        ));
  }

  /// Mueve dinero de una cuenta a otra. `null` significa "Efectivo / sin
  /// tarjeta". No cuenta como ingreso ni como gasto: se guardan dos filas
  /// (sale / entra) unidas por un código en `rawSmsBody` ("transfer:" más un código).
  Future<void> addTransfer({
    String? outId,
    String? inId,
    required String? fromCardId,
    required String? toCardId,
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    final categoryId = await _transferCategoryId();
    final group = _uuid.v4();
    await db.transaction(() async {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            id: outId ?? _uuid.v4(),
            type: TxType.transferOut,
            amount: amount,
            categoryId: categoryId,
            description: Value(description),
            date: date,
            source: const Value(TxSource.transfer),
            rawSmsBody: Value('transfer:$group'),
            cardId: Value(fromCardId),
          ));
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            id: inId ?? _uuid.v4(),
            type: TxType.transferIn,
            amount: amount,
            categoryId: categoryId,
            description: Value(description),
            date: date,
            source: const Value(TxSource.transfer),
            rawSmsBody: Value('transfer:$group'),
            cardId: Value(toCardId),
          ));
    });
  }

  /// Borra una transferencia completa (las dos filas).
  Future<void> deleteTransfer(String group) {
    return (db.delete(db.transactions)
          ..where((t) => t.rawSmsBody.equals('transfer:$group')))
        .go();
  }

  Future<String> _transferCategoryId() async {
    final existing = await (db.select(db.categories)
          ..where((c) => c.type.equals(TxType.transfer)))
        .get();
    if (existing.isNotEmpty) return existing.first.id;
    final id = _uuid.v4();
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: 'Transferencia',
          type: TxType.transfer,
          icon: 'swap_horiz',
          color: 'FF0A84FF',
          isArchived: const Value(true),
        ));
    return id;
  }

  Future<void> update(Transaction tx) {
    return db.update(db.transactions).replace(tx);
  }

  Future<void> delete(String id) {
    return (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Borra TODAS las transacciones. Usado en "Borrar todos los datos" en
  /// Ajustes, para que el usuario pueda empezar de cero.
  Future<void> deleteAll() {
    return db.delete(db.transactions).go();
  }
}

/// Código de la transferencia a la que pertenece un movimiento, o null si
/// no es una transferencia.
String? transferGroupOf(Transaction tx) {
  final raw = tx.rawSmsBody;
  if (raw != null && raw.startsWith('transfer:')) {
    return raw.substring('transfer:'.length);
  }
  return null;
}
