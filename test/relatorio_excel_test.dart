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
              : null,
      ],
  ];
}

void main() {
  test('gera cabeçalho e uma linha por aluno, na ordem recebida', () {
    final bytes = gerarXlsxNotas(const [
      LinhaNota(aluno: 'Ana Souza', prova: 'P1 — Matemática', nota: 8.5),
      LinhaNota(aluno: 'Bruno Lima', prova: 'P1 — Matemática', nota: 6),
    ]);

    final linhas = lerAba(bytes);
    expect(linhas, hasLength(3));
    expect(linhas[0], ['Aluno', 'Prova', 'Nota']);
    expect(linhas[1], ['Ana Souza', 'P1 — Matemática', 8.5]);
    expect(linhas[2], ['Bruno Lima', 'P1 — Matemática', 6.0]);
  });

  test('nota ausente vira célula vazia, não zero', () {
    final linhas = lerAba(
      gerarXlsxNotas(const [LinhaNota(aluno: 'Carla', prova: 'P1')]),
    );
    expect(linhas[1], ['Carla', 'P1', null]);
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
        LinhaNota(aluno: '=1+1 João Çedilha', prova: 'Avaliação', nota: 10),
      ]),
    );
    expect(linhas[1], ['=1+1 João Çedilha', 'Avaliação', 10.0]);
  });
}
