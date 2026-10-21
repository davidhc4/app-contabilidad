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

  Stream<MonthSummary> watchMonthSummary(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return watchInRange(start, end).map((items) {
      double income = 0, expense = 0;
      for (final item in items) {
        if (item.transaction.type == TxType.income) {
          income += item.transaction.amount;
        } else {
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
    required String type,
    required double amount,
    required String categoryId,
    String description = '',
    required DateTime date,
    String source = TxSource.manual,
    String? rawSmsBody,
  }) {
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: _uuid.v4(),
          type: type,
          amount: amount,
          categoryId: categoryId,
          description: Value(description),
          date: date,
          source: Value(source),
          rawSmsBody: Value(rawSmsBody),
        ));
  }

  Future<void> update(Transaction tx) {
    return db.update(db.transactions).replace(tx);
  }

  Future<void> delete(String id) {
    return (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }
}
