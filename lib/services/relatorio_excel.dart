// Gera a planilha de notas (.xlsx) a partir de uma lista de [LinhaNota].
// Devolve os bytes do arquivo; quem chama decide se salva ou compartilha.
//
// Formato (o sistema acadêmico não informou um, então este é o definido pelo
// grupo; ver docs/formato-relatorio-notas.md):
//   aba "Notas", linha 1 = cabeçalho, uma linha por aluno, colunas
//   Matrícula (texto) | Nome (texto) | Nota (número 0 a 10, 2 casas) |
//   Data (data da correção, dd/mm/aaaa).

import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/linha_nota.dart';

const String nomeAbaNotas = 'Notas';

const List<String> colunasRelatorioNotas = [
  'Matrícula',
  'Nome',
  'Nota',
  'Data',
];

Uint8List gerarXlsxNotas(List<LinhaNota> linhas) {
  final excel = Excel.createExcel();

  // createExcel() já cria a aba "Sheet1"; renomeia para "Notas".
  excel.rename(excel.getDefaultSheet()!, nomeAbaNotas);
  final aba = excel[nomeAbaNotas];

  aba.appendRow([for (final c in colunasRelatorioNotas) TextCellValue(c)]);
  final cabecalho = CellStyle(bold: true);
  for (var col = 0; col < colunasRelatorioNotas.length; col++) {
    aba
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
            .cellStyle =
        cabecalho;
  }

  final estiloNota = CellStyle(numberFormat: NumFormat.standard_2);
  final estiloData = CellStyle(
    numberFormat: NumFormat.custom(formatCode: 'dd/mm/yyyy'),
  );

  for (var i = 0; i < linhas.length; i++) {
    final linha = linhas[i];
    final nota = linha.nota;
    final data = linha.data;
    aba.appendRow([
      // Texto, para não perder zero à esquerda da matrícula.
      TextCellValue(linha.matricula),
      TextCellValue(linha.aluno),
      nota == null ? null : DoubleCellValue((nota * 100).round() / 100),
      data == null ? null : DateCellValue.fromDateTime(data),
    ]);
    final linhaNaPlanilha = i + 1;
    aba
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 2,
                rowIndex: linhaNaPlanilha,
              ),
            )
            .cellStyle =
        estiloNota;
    aba
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 3,
                rowIndex: linhaNaPlanilha,
              ),
            )
            .cellStyle =
        estiloData;
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Não foi possível gerar o arquivo .xlsx');
  }
  return Uint8List.fromList(bytes);
}
