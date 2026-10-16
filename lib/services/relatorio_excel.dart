// Gera a planilha de notas (.xlsx) a partir de uma lista de [LinhaNota].
// Devolve os bytes do arquivo; quem chama decide se salva ou compartilha.

import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/linha_nota.dart';

const String nomeAbaNotas = 'Notas';

Uint8List gerarXlsxNotas(List<LinhaNota> linhas) {
  final excel = Excel.createExcel();

  // createExcel() já cria a aba "Sheet1"; renomeia para "Notas".
  excel.rename(excel.getDefaultSheet()!, nomeAbaNotas);
  final aba = excel[nomeAbaNotas];

  final cabecalho = CellStyle(bold: true);
  aba.appendRow([
    TextCellValue('Aluno'),
    TextCellValue('Prova'),
    TextCellValue('Nota'),
  ]);
  for (var col = 0; col < 3; col++) {
    aba
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
            .cellStyle =
        cabecalho;
  }

  for (final linha in linhas) {
    aba.appendRow([
      TextCellValue(linha.aluno),
      TextCellValue(linha.prova),
      linha.nota == null ? null : DoubleCellValue(linha.nota!),
    ]);
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Não foi possível gerar o arquivo .xlsx');
  }
  return Uint8List.fromList(bytes);
}
