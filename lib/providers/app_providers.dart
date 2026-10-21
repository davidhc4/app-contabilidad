import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/sms_sender_repository.dart';
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
