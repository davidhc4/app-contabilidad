import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

class CategoryRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  CategoryRepository(this.db);

  Stream<List<Category>> watchByType(String type) {
    return (db.select(db.categories)
          ..where((c) => c.type.equals(type) & c.isArchived.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Stream<List<Category>> watchAll() {
    return (db.select(db.categories)
          ..where((c) => c.isArchived.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<String> addCustom({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    final id = _uuid.v4();
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name,
          type: type,
          icon: icon,
          color: color,
          isCustom: const Value(true),
        ));
    return id;
  }

  Future<void> archive(String id) {
    return (db.update(db.categories)..where((c) => c.id.equals(id)))
        .write(const CategoriesCompanion(isArchived: Value(true)));
  }
}
