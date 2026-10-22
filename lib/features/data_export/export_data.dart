import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/tables.dart';
import '../../providers/app_providers.dart';

const kExportHeader = <String>[
  'Fecha', 'Hora', 'Tipo', 'Categoría', 'Monto',
  'Descripción', 'Tarjeta', 'Origen', 'ID',
];

/// Todos los movimientos como filas (la más antigua primero), en el mismo
/// orden de columnas que [kExportHeader].
Future<List<List<Object>>> buildExportRows(WidgetRef ref) async {
  final items = await ref.read(transactionRepositoryProvider).watchAll().first;
  final cards = await ref.read(cardRepositoryProvider).watchAll().first;
  final cardNames = {
    for (final c in cards) c.id: '${c.name} •••• ${c.lastFourDigits}',
  };
  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat('HH:mm');

  return [
    for (final item in items.reversed)
      [
        dateFormat.format(item.transaction.date),
        timeFormat.format(item.transaction.date),
        switch (item.transaction.type) {
          TxType.income => 'Ingreso',
          TxType.transferOut => 'Transferencia (sale)',
          TxType.transferIn => 'Transferencia (entra)',
          _ => 'Gasto',
        },
        item.category.name,
        item.transaction.amount.round(),
        item.transaction.description,
        cardNames[item.transaction.cardId] ?? '',
        switch (item.transaction.source) {
          TxSource.sms => 'SMS',
          TxSource.transfer => 'Transferencia',
          _ => 'Manual',
        },
        item.transaction.id,
      ],
  ];
}

String _csvCell(Object value) {
  final text = value.toString();
  if (text.contains(',') || text.contains('"') || text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// Crea el archivo CSV con todos los movimientos y lo devuelve junto con
/// la cantidad de filas.
Future<({File file, int count})> createCsvFile(WidgetRef ref) async {
  final rows = await buildExportRows(ref);
  final buffer = StringBuffer('﻿') // BOM: Excel muestra bien las tildes
    ..writeln(kExportHeader.join(','));
  for (final row in rows) {
    buffer.writeln(row.map(_csvCell).join(','));
  }
  final dir = await getTemporaryDirectory();
  final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final file = File(p.join(dir.path, 'movimientos_$stamp.csv'));
  await file.writeAsString(buffer.toString());
  return (file: file, count: rows.length);
}

/// Abre el menú de compartir del celular para mandar el archivo por correo,
/// Drive, OneDrive, WhatsApp, etc.
Future<void> shareCsvFile(File file) {
  return Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: 'Movimientos - Contabilidad personal',
    text: 'Copia de mis movimientos (abre el archivo con Excel o Google Sheets).',
  );
}
