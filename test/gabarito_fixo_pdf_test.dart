import 'dart:convert';

import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/layout_folha.dart';
import 'package:flutter_dart/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

PdfService _servico() => PdfService(
  criarDocumento: () async => pw.Document(
    compress: false,
    theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    ),
  ),
);

VersaoProva _versao(List<int> alternativas) => VersaoProva(
  id: 'v1',
  qrCode: 'qr-v1',
  questoes: [
    for (var i = 0; i < alternativas.length; i++)
      () {
        final alts = [for (var a = 0; a < alternativas[i]; a++) 'alt $a'];
        return QuestaoNaVersao(
          questao: Questao(
            id: 'q$i',
            materiaId: 'm',
            enunciado: 'Enunciado $i',
            alternativas: alts,
            respostaCorreta: 0,
          ),
          alternativas: alts,
          respostaCorreta: 0,
        );
      }(),
  ],
);

int _paginasDeGabarito(List<int> bytes) =>
    RegExp(r'GABARITO\)\]TJ').allMatches(latin1.decode(bytes)).length;

void main() {
  test('o PDF tem tantas páginas de gabarito quanto a grade fixa', () async {
    for (final alternativas in [
      [5, 5, 4],
      List.filled(130, 5),
      [for (var i = 0; i < 200; i++) i == 3 ? 12 : 5],
    ]) {
      final bytes = await _servico().gerarPdfVersao(_versao(alternativas));
      expect(
        _paginasDeGabarito(bytes),
        LayoutFolha.paginasDoGabarito(alternativas),
        reason: '${alternativas.length} questões',
      );
    }
  });

  test('o gabarito não muda com a margem do editor de layout', () async {
    // A margem do editor vale só para o caderno; o leitor depende das
    // posições fixas do gabarito.
    final alternativas = List.filled(130, 5);
    final estreita = await _servico().gerarPdfVersao(
      _versao(alternativas),
      margem: LayoutFolha.margemMinima,
    );
    final larga = await _servico().gerarPdfVersao(
      _versao(alternativas),
      margem: LayoutFolha.margemMaxima,
    );
    expect(_paginasDeGabarito(estreita), _paginasDeGabarito(larga));
  });
}
