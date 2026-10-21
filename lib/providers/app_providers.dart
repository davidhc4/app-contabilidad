import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/repositories/card_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/sms_sender_repository.dart';
import '../data/repositories/statistics_models.dart';
import '../data/repositories/transaction_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final smsSenderRepositoryProvider = Provider<SmsSenderRepository>((ref) {
  return SmsSenderRepository(ref.watch(databaseProvider));
});

final settingsStreamProvider = StreamProvider((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthSummaryProvider = StreamProvider((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionRepositoryProvider).watchMonthSummary(month);
});

final expenseByCategoryProvider = StreamProvider((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchExpenseByCategory(month);
});

final allTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final expenseCategoriesProvider = StreamProvider((ref) {
  return ref.watch(categoryRepositoryProvider).watchByType('expense');
});

final incomeCategoriesProvider = StreamProvider((ref) {
  return ref.watch(categoryRepositoryProvider).watchByType('income');
});

/// -------- Tarjetas --------

final cardsProvider = StreamProvider((ref) {
  return ref.watch(cardRepositoryProvider).watchAll();
});

/// Transacciones de una tarjeta específica. Se usa `.family` para poder
/// pedir el stream de cualquier tarjeta por su id.
final transactionsByCardProvider =
    StreamProvider.family<List<TransactionWithCategory>, String>(
  (ref, cardId) {
    return ref.watch(transactionRepositoryProvider).watchByCard(cardId);
  },
);

/// -------- Pantalla de Estadísticas --------

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) {
  return StatsPeriod.month;
});

final statsRangeProvider = Provider<DateRange>((ref) {
  final period = ref.watch(statsPeriodProvider);
  return rangeForPeriod(period);
});

final statsAggregateProvider = StreamProvider((ref) {
  final period = ref.watch(statsPeriodProvider);
  final range = ref.watch(statsRangeProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchInRange(range.start, range.end)
      .map((items) => StatsAggregate.build(items, range, period));
});
