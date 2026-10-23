import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';
import 'csv_parser.dart';
import 'export_data.dart';

/// Resumen de lo que pasó al importar una copia.
class ImportResult {
  final int added;
  final int skipped;
  final int newCards;
  final int newCategories;
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.newCards,
    required this.newCategories,
  });
}

const _cardGradients = <List<String>>[
  ['FF0A84FF', 'FF64D2FF'],
  ['FF30D158', 'FF63E6E2'],
  ['FFBF5AF2', 'FFFF375F'],
  ['FFFF9F0A', 'FFFF453A'],
];

class _Row {
  final String id;
  final DateTime date;
  final String type;
  final String category;
  final double amount;
  final String description;
  final String card;
  final String origin;
  const _Row({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.card,
    required this.origin,
  });
}

/// Lee el archivo CSV que creó "Compartir copia en CSV" y agrega a la app
/// los movimientos que todavía no estén. Importar dos veces el mismo
/// archivo no duplica nada.
Future<ImportResult> importCsvFile(WidgetRef ref, File file) async {
  final text = await file.readAsString();
  final rows = parseCsv(text);
  if (rows.isEmpty) {
    throw const FormatException('El archivo está vacío');
  }
  final header = rows.first.map((c) => c.trim()).toList();
  int col(String name) => header.indexOf(name);
  final iDate = col('Fecha');
  final iType = col('Tipo');
  final iAmount = col('Monto');
  if (iDate < 0 || iType < 0 || iAmount < 0) {
    throw const FormatException(
        'Este archivo no es una copia de Bolsillo (faltan columnas)');
  }
  final iTime = col('Hora');
  final iCategory = col('Categoría');
  final iDesc = col('Descripción');
  final iCard = col('Tarjeta');
  final iOrigin = col('Origen');
  final iId = col('ID');

  String cell(List<String> r, int i) =>
      (i >= 0 && i < r.length) ? r[i].trim() : '';

  final parsed = <_Row>[];
  var skipped = 0;
  for (final r in rows.skip(1)) {
    final time = cell(r, iTime);
    final date = DateTime.tryParse(
        '${cell(r, iDate)} ${time.isEmpty ? '00:00' : time}');
    final amount = double.tryParse(cell(r, iAmount));
    if (date == null || amount == null || amount <= 0) {
      skipped++;
      continue;
    }
    parsed.add(_Row(
      id: cell(r, iId),
      date: date,
      type: cell(r, iType),
      category: cell(r, iCategory),
      amount: amount,
      description: iDesc >= 0 && iDesc < r.length ? r[iDesc] : '',
      card: cell(r, iCard),
      origin: cell(r, iOrigin),
    ));
  }

  final txRepo = ref.read(transactionRepositoryProvider);
  final cardRepo = ref.read(cardRepositoryProvider);
  final catRepo = ref.read(categoryRepositoryProvider);

  final knownIds = <String>{
    for (final t in await txRepo.watchAll().first) t.transaction.id,
  };
  final cards = await cardRepo.watchAll().first;
  final categories = await catRepo.watchAll().first;

  final cardByLabel = <String, String>{
    for (final c in cards) '${c.name} •••• ${c.lastFourDigits}': c.id,
  };
  final categoryByKey = <String, String>{
    for (final c in categories) '${c.type}|${c.name.toLowerCase()}': c.id,
  };
  var newCards = 0;
  var newCategories = 0;

  Future<String?> cardIdFor(String label) async {
    if (label.isEmpty) return null;
    final existing = cardByLabel[label];
    if (existing != null) return existing;
    final match = RegExp(r'^(.*) •••• (\S+)$').firstMatch(label);
    final name = match?.group(1) ?? label;
    final digits = match?.group(2) ?? '0000';
    final colors = _cardGradients[newCards % _cardGradients.length];
    final id = await cardRepo.addCard(
      name: name,
      lastFourDigits: digits,
      network: CardNetwork.other,
      colorStart: colors[0],
      colorEnd: colors[1],
    );
    cardByLabel[label] = id;
    newCards++;
    return id;
  }

  Future<String> categoryIdFor(String name, String type) async {
    final clean = name.isEmpty ? 'Otros' : name;
    final key = '$type|${clean.toLowerCase()}';
    final existing = categoryByKey[key];
    if (existing != null) return existing;
    final id = await catRepo.addCustom(
      name: clean,
      type: type,
      icon: 'category',
      color: type == TxType.income ? 'FF30D158' : 'FF8E8E93',
    );
    categoryByKey[key] = id;
    newCategories++;
    return id;
  }

  var added = 0;
  final outs = <_Row>[];
  final ins = <_Row>[];

  for (final r in parsed) {
    if (r.type == 'Transferencia (sale)') {
      outs.add(r);
      continue;
    }
    if (r.type == 'Transferencia (entra)') {
      ins.add(r);
      continue;
    }
    if (r.id.isNotEmpty && knownIds.contains(r.id)) {
      skipped++;
      continue;
    }
    final type = r.type == 'Ingreso' ? TxType.income : TxType.expense;
    await txRepo.add(
      id: r.id.isEmpty ? null : r.id,
      type: type,
      amount: r.amount,
      categoryId: await categoryIdFor(r.category, type),
      description: r.description,
      date: r.date,
      source: r.origin == 'SMS' ? TxSource.sms : TxSource.manual,
      cardId: await cardIdFor(r.card),
    );
    added++;
  }

  // Cada transferencia son dos filas: se juntan por fecha, monto y nota.
  final usedIns = <int>{};
  for (final out in outs) {
    final match = ins.indexWhere((i) =>
        !usedIns.contains(ins.indexOf(i)) &&
        i.date == out.date &&
        i.amount == out.amount &&
        i.description == out.description);
    if (match < 0 || (out.id.isNotEmpty && knownIds.contains(out.id))) {
      skipped++;
      continue;
    }
    usedIns.add(match);
    final inn = ins[match];
    await txRepo.addTransfer(
      outId: out.id.isEmpty ? null : out.id,
      inId: inn.id.isEmpty ? null : inn.id,
      fromCardId: await cardIdFor(out.card),
      toCardId: await cardIdFor(inn.card),
      amount: out.amount,
      date: out.date,
      description: out.description,
    );
    added++;
  }

  return ImportResult(
    added: added,
    skipped: skipped,
    newCards: newCards,
    newCategories: newCategories,
  );
}
