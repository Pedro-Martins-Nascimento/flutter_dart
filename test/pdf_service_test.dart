import 'dart:convert';

import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF sem compressão e com fonte embutida (Helvetica): assim o texto fica
/// legível nos bytes do arquivo e dá para ver em que página cada trecho caiu.
PdfService _servico() => PdfService(
  criarDocumento: () async => pw.Document(
    compress: false,
    theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    ),
  ),
);

/// Questão `n` com marcas únicas no enunciado e em cada alternativa
/// ("Q07-ENUN", "Q07-ALT0"...). [linhas] deixa o enunciado mais comprido.
QuestaoNaVersao _questao(int n, {int linhas = 1, int alternativas = 4}) {
  final id = 'Q${n.toString().padLeft(2, '0')}';
  final alts = [for (var i = 0; i < alternativas; i++) '$id-ALT$i resposta'];
  final enunciado =
      '$id-ENUN ${List.filled(linhas, 'texto do enunciado ' * 6).join(' ')}';
  return QuestaoNaVersao(
    questao: Questao(
      id: id,
      materiaId: 'm',
      enunciado: enunciado,
      alternativas: alts,
      respostaCorreta: 0,
    ),
    alternativas: alts,
    respostaCorreta: 0,
  );
}

VersaoProva _versao(List<QuestaoNaVersao> questoes) =>
    VersaoProva(id: 'v1', qrCode: 'qr-v1', questoes: questoes);

/// Texto de cada página do PDF, na ordem.
List<String> _textoPorPagina(List<int> bytes) {
  final texto = latin1.decode(bytes);
  final streams =
      RegExp(r'(?<!end)stream\r?\n(.*?)\r?\nendstream', dotAll: true)
          .allMatches(texto)
          .map((m) => m.group(1)!)
          .where((s) => s.contains('TJ') || s.contains('Tj'))
          .toList();
  return streams;
}

/// Páginas em que aparece alguma marca da questão [n] ("Q07-").
Set<int> _paginasDaQuestao(List<String> paginas, int n) {
  final id = 'Q${n.toString().padLeft(2, '0')}-';
  return {
    for (var i = 0; i < paginas.length; i++)
      if (paginas[i].contains(id)) i,
  };
}

void main() {
  test('o PDF de teste sai com várias páginas e texto legível', () async {
    final bytes = await _servico().gerarPdfVersao(
      _versao([for (var i = 1; i <= 40; i++) _questao(i, linhas: 2)]),
    );
    final paginas = _textoPorPagina(bytes);
    expect(paginas.length, greaterThan(1));
    expect(_paginasDaQuestao(paginas, 1), {0});
  });

  test('questão mais alta que a página é cortada em vez de falhar', () async {
    // 60 alternativas passam de uma página, mas cada pedaço cabe: o PDF tem
    // que sair (com a questão 2 dividida) e não pode ser derrubado.
    final bytes = await _servico().gerarPdfVersao(
      _versao([_questao(1), _questao(2, alternativas: 60), _questao(3)]),
    );
    final paginas = _textoPorPagina(bytes);
    expect(_paginasDaQuestao(paginas, 1), isNotEmpty);
    expect(_paginasDaQuestao(paginas, 3), isNotEmpty);
  });

  test('nenhuma questão é cortada entre duas páginas', () async {
    // Varia o tamanho do enunciado para a quebra de página cair em pontos
    // diferentes de uma questão.
    for (var linhas = 1; linhas <= 4; linhas++) {
      for (var total = 8; total <= 30; total++) {
        final bytes = await _servico().gerarPdfVersao(
          _versao([
            for (var i = 1; i <= total; i++) _questao(i, linhas: linhas),
          ]),
        );
        final paginas = _textoPorPagina(bytes);
        for (var q = 1; q <= total; q++) {
          expect(
            _paginasDaQuestao(paginas, q),
            hasLength(1),
            reason: 'questão $q cortada ($total questões, $linhas linhas)',
          );
        }
      }
    }
  });
}
