import 'package:app_contabilidad/features/data_export/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCsv', () {
    test('lee celdas simples y quita el BOM', () {
      final rows = parseCsv('﻿Fecha,Tipo\n2026-10-22,Gasto\n');
      expect(rows, [
        ['Fecha', 'Tipo'],
        ['2026-10-22', 'Gasto'],
      ]);
    });

    test('respeta comillas, comas y saltos de línea dentro de una celda', () {
      final rows = parseCsv('a,"hola, ""mundo""",c\r\n"linea1\nlinea2",x,y');
      expect(rows[0], ['a', 'hola, "mundo"', 'c']);
      expect(rows[1], ['linea1\nlinea2', 'x', 'y']);
    });

    test('ignora filas vacías', () {
      expect(parseCsv('a,b\n\n\nc,d\n').length, 2);
    });
  });
}
