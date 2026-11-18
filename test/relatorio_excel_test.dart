import 'package:excel/excel.dart';
import 'package:flutter_dart/models/linha_nota.dart';
import 'package:flutter_dart/services/relatorio_excel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lê os bytes de volta como planilha, como o Excel faria ao abrir.
List<List<Object?>> lerAba(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  final aba = excel[nomeAbaNotas];
  return [
    for (final linha in aba.rows)
      [
        for (final c in linha)
          c?.value is TextCellValue
              ? (c!.value as TextCellValue).value.toString()
              : c?.value is DoubleCellValue
              ? (c!.value as DoubleCellValue).value
              : c?.value is IntCellValue
              ? (c!.value as IntCellValue).value.toDouble()
              : c?.value is DateCellValue
              ? (c!.value as DateCellValue).asDateTimeLocal()
              : null,
      ],
  ];
}

void main() {
  test('gera cabeçalho e uma linha por aluno, na ordem recebida', () {
    final bytes = gerarXlsxNotas([
      LinhaNota(
        matricula: '2026001',
        aluno: 'Ana Souza',
        nota: 8.5,
        data: DateTime(2026, 5, 10),
      ),
      LinhaNota(
        matricula: '2026002',
        aluno: 'Bruno Lima',
        nota: 6,
        data: DateTime(2026, 5, 11),
      ),
    ]);

    final linhas = lerAba(bytes);
    expect(linhas, hasLength(3));
    expect(linhas[0], ['Matrícula', 'Nome', 'Nota', 'Data']);
    expect(linhas[1], ['2026001', 'Ana Souza', 8.5, DateTime(2026, 5, 10)]);
    expect(linhas[2], ['2026002', 'Bruno Lima', 6.0, DateTime(2026, 5, 11)]);
  });

  test('nota e data ausentes viram células vazias, não zero', () {
    final linhas = lerAba(
      gerarXlsxNotas(const [LinhaNota(matricula: '7', aluno: 'Carla')]),
    );
    expect(linhas[1], ['7', 'Carla', null, null]);
  });

  test('matrícula com zero à esquerda continua texto', () {
    final linhas = lerAba(
      gerarXlsxNotas(const [LinhaNota(matricula: '000123', aluno: 'Davi')]),
    );
    expect(linhas[1][0], '000123');
  });

  test('nota é arredondada para 2 casas', () {
    final linhas = lerAba(
      gerarXlsxNotas(const [
        LinhaNota(matricula: '1', aluno: 'Eva', nota: 10 / 3),
      ]),
    );
    expect(linhas[1][2], 3.33);
  });

  test('nota e data saem com formato de número e de data', () {
    final excel = Excel.decodeBytes(
      gerarXlsxNotas([
        LinhaNota(
          matricula: '1',
          aluno: 'Fábio',
          nota: 7,
          data: DateTime(2026, 5, 10),
        ),
      ]),
    );
    final aba = excel[nomeAbaNotas];
    final nota = aba.cell(CellIndex.indexByString('C2')).cellStyle;
    final data = aba.cell(CellIndex.indexByString('D2')).cellStyle;
    expect(nota?.numberFormat.formatCode, '0.00');
    expect(data?.numberFormat.formatCode, 'dd/mm/yyyy');
  });

  test('lista vazia gera só o cabeçalho', () {
    expect(lerAba(gerarXlsxNotas(const [])), hasLength(1));
  });

  test('só existe a aba "Notas"', () {
    final excel = Excel.decodeBytes(gerarXlsxNotas(const []));
    expect(excel.tables.keys, [nomeAbaNotas]);
  });

  test('acentos e texto começando com "=" são guardados como texto', () {
    final linhas = lerAba(
      gerarXlsxNotas(const [
        LinhaNota(matricula: '1', aluno: '=1+1 João Çedilha', nota: 10),
      ]),
    );
    expect(linhas[1][1], '=1+1 João Çedilha');
    expect(linhas[1][2], 10.0);
  });
}
