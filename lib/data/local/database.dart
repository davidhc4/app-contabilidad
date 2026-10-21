import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Categories, Transactions, SmsBankSenders, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seed(this);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(appSettings, appSettings.monthlyBudget);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_contabilidad.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

Future<void> _seed(AppDatabase db) async {
  const uuid = Uuid();

  await db.into(db.appSettings).insert(const AppSettingsCompanion());

  final expenseCategories = <List<String>>[
    ['Comida', 'restaurant', 'FFFF9F0A'],
    ['Transporte', 'directions_car', 'FF0A84FF'],
    ['Hogar', 'home', 'FF64D2FF'],
    ['Entretenimiento', 'theaters', 'FFBF5AF2'],
    ['Salud', 'favorite', 'FFFF453A'],
    ['Compras', 'shopping_bag', 'FFFF375F'],
    ['Servicios', 'receipt_long', 'FF8E8E93'],
    ['Otros', 'more_horiz', 'FF636366'],
  ];
  final incomeCategories = <List<String>>[
    ['Salario', 'work', 'FF30D158'],
    ['Freelance', 'laptop_mac', 'FF63E6E2'],
    ['Regalos', 'card_giftcard', 'FFFF9F0A'],
    ['Inversiones', 'trending_up', 'FF0A84FF'],
    ['Otros', 'more_horiz', 'FF636366'],
  ];

  for (final c in expenseCategories) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: uuid.v4(),
          name: c[0],
          type: TxType.expense,
          icon: c[1],
          color: c[2],
        ));
  }
  for (final c in incomeCategories) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: uuid.v4(),
          name: c[0],
          type: TxType.income,
          icon: c[1],
          color: c[2],
        ));
  }
}
