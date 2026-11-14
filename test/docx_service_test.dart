import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/docx_service.dart';
import 'package:flutter_dart/services/provas_repository.dart';

void main() {
  test('gera um docx com versões, alternativas e quebras de página', () {
    final prova = ProvaGerada(
      id: 'p1',
      nome: 'Prova de Ciências',
      materia: 'Ciências',
      turma: '7A',
      criadoEm: DateTime(2026, 11, 14),
      versoes: [
        VersaoProva(
          id: 'v1',
          qrCode: 'nao-incluir',
          materia: 'Ciências',
          professor: 'Prof. Ana',
          turma: '7A',
          provaNome: 'Prova de Ciências',
          questoes: [
            QuestaoNaVersao(
              questao: Questao(
                id: 'q1',
                materiaId: 'c',
                enunciado: 'Qual é a ordem?',
                alternativas: ['original', 'distrator'],
                respostaCorreta: 0,
              ),
              alternativas: ['segunda', 'primeira'],
              respostaCorreta: 0,
            ),
          ],
        ),
        VersaoProva(
          id: 'v2',
          qrCode: 'nao-incluir',
          materia: 'Ciências',
          professor: 'Prof. Ana',
          turma: '7A',
          provaNome: 'Prova de Ciências',
          questoes: [
            QuestaoNaVersao(
              questao: Questao(
                id: 'q2',
                materiaId: 'c',
                enunciado: 'Outra questão',
                alternativas: ['a', 'b'],
                respostaCorreta: 1,
              ),
              alternativas: ['B primeiro', 'A depois'],
              respostaCorreta: 0,
            ),
          ],
        ),
      ],
    );

    final archive = ZipDecoder().decodeBytes(gerarDocx(prova));
    expect(
      archive.files.map((file) => file.name),
      containsAll(<String>[
        '[Content_Types].xml',
        '_rels/.rels',
        'word/document.xml',
      ]),
    );

    final xml = utf8.decode(
      (archive.findFile('word/document.xml')!.content as List<int>),
    );
    expect(xml, contains('Qual é a ordem?'));
    expect(xml.indexOf('segunda'), lessThan(xml.indexOf('primeira')));
    expect(xml, contains('Outra questão'));
    expect(xml.indexOf('B primeiro'), lessThan(xml.indexOf('A depois')));
    expect(xml, contains('<w:br w:type="page"/>'));
    expect(xml, isNot(contains('nao-incluir')));
  });
}
