import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:flutter_dart/models/aluno.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/docx_service.dart';
import 'package:flutter_dart/models/prova_gerada.dart';

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
    expect(xml, contains('<w:r><w:br w:type="page"/></w:r>'));
    expect(xml, isNot(contains('<w:p><w:br')));
    expect(xml, isNot(contains('nao-incluir')));
    expect(() => XmlDocument.parse(xml), returnsNormally);
  });

  test('usa nome do aluno vinculado e nunca expõe o id', () {
    final prova = _provaComAluno('aluno-1');

    final xml = _documentXml(
      gerarDocx(prova, alunos: [Aluno(id: 'aluno-1', nome: 'Ana Beatriz')]),
    );

    expect(xml, contains('Aluno: Ana Beatriz'));
    expect(xml, isNot(contains('aluno-1')));
  });

  test('deixa aluno em branco sem vínculo ou sem aluno correspondente', () {
    final semVinculo = _documentXml(gerarDocx(_provaComAluno(null)));
    final idAusente = _documentXml(gerarDocx(_provaComAluno('inexistente')));

    expect(semVinculo, contains('Aluno: ____________________'));
    expect(idAusente, contains('Aluno: ____________________'));
    expect(idAusente, isNot(contains('inexistente')));
  });
}

ProvaGerada _provaComAluno(String? alunoId) => ProvaGerada(
      id: 'p-aluno',
      nome: 'Prova',
      materia: 'Ciências',
      turma: '7A',
      criadoEm: DateTime(2026, 11, 14),
      versoes: [
        VersaoProva(
          id: 'v1',
          qrCode: 'q',
          alunoId: alunoId,
          questoes: [
            QuestaoNaVersao(
              questao: Questao(
                id: 'q1',
                materiaId: 'c',
                enunciado: 'Enunciado',
                alternativas: ['A', 'B'],
                respostaCorreta: 0,
              ),
              alternativas: ['A', 'B'],
              respostaCorreta: 0,
            ),
          ],
        ),
      ],
    );

String _documentXml(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  return utf8.decode(
    archive.findFile('word/document.xml')!.content as List<int>,
  );
}
