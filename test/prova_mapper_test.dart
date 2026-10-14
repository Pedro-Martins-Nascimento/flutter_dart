import 'dart:convert';
import 'dart:math';

import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/prova_mapper.dart';
import 'package:flutter_dart/services/provas_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tamanho de um valor segundo as regras documentadas do Firestore:
/// texto = bytes UTF-8 + 1, número = 8, bool/null = 1, data = 16,
/// lista = soma dos itens, mapa = soma de (nome do campo + 1 + valor).
int tamanhoFirestore(Object? v) {
  if (v == null || v is bool) return 1;
  if (v is num) return 8;
  if (v is DateTime) return 16;
  if (v is String) return utf8.encode(v).length + 1;
  if (v is List) return v.fold(0, (s, e) => s + tamanhoFirestore(e));
  if (v is Map) {
    return v.entries.fold(
      0,
      (s, e) =>
          s +
          utf8.encode(e.key as String).length +
          1 +
          tamanhoFirestore(e.value),
    );
  }
  throw ArgumentError('tipo sem regra: ${v.runtimeType}');
}

/// Monta uma prova falsa: [versoes] versões com [questoes] questões cada,
/// com enunciados/alternativas de comprimento [tamEnunciado]/[tamAlt].
ProvaGerada provaFalsa({
  required int versoes,
  required int questoes,
  required int tamEnunciado,
  required int tamAlt,
  int alternativas = 5,
}) {
  final rnd = Random(1);
  String texto(int n) =>
      String.fromCharCodes(List.generate(n, (_) => 97 + rnd.nextInt(26)));
  final banco = [
    for (var i = 0; i < questoes; i++)
      Questao(
        id: 'q${1000 + i}',
        materiaId: 'mat1',
        enunciado: texto(tamEnunciado),
        alternativas: List.generate(alternativas, (_) => texto(tamAlt)),
        respostaCorreta: 1,
      ),
  ];
  return ProvaGerada(
    id: 'pg_1',
    nome: 'Prova de teste',
    materia: 'Matemática',
    turma: 'Turma A',
    criadoEm: DateTime(2026, 1, 1),
    versoes: List.generate(
      versoes,
      (i) => VersaoProva(
        id: 'v${i + 1}',
        qrCode: 'PG_1-V${i + 1}',
        alunoId: 'aluno${i + 1}',
        questoes: [
          for (final q in banco)
            QuestaoNaVersao(
              questao: q,
              alternativas: q.alternativas.reversed.toList(),
              respostaCorreta: q.alternativas.length - 1 - q.respostaCorreta,
            ),
        ],
      ),
    ),
  );
}

void main() {
  group('ProvaMapper', () {
    test('ida e volta preserva prova e versões', () {
      final prova = provaFalsa(
        versoes: 2,
        questoes: 3,
        tamEnunciado: 40,
        tamAlt: 10,
        alternativas: 4,
      );
      prova.versoes[1].alunoId = null;

      final mapa = ProvaMapper.provaParaMapa(prova);
      final versoes = [
        for (final v in prova.versoes)
          ProvaMapper.versaoDeMapa(v.id, ProvaMapper.versaoParaMapa(v)),
      ];
      final volta = ProvaMapper.provaDeMapa(prova.id, mapa, versoes: versoes);

      expect(volta.id, prova.id);
      expect(volta.nome, prova.nome);
      expect(volta.turma, prova.turma);
      expect(volta.criadoEm, prova.criadoEm);
      expect(mapa['totalVersoes'], 2);
      expect(volta.versoes[0].alunoId, 'aluno1');
      expect(volta.versoes[1].alunoId, isNull);
      final q0 = volta.versoes[0].questoes[0];
      final original = prova.versoes[0].questoes[0];
      expect(q0.questao.enunciado, original.questao.enunciado);
      expect(q0.alternativas, original.alternativas);
      expect(q0.respostaCorreta, original.respostaCorreta);
      expect(q0.questao.respostaCorreta, original.questao.respostaCorreta);
    });

    test('aceita criadoEm como texto ISO', () {
      final mapa = ProvaMapper.provaParaMapa(
        provaFalsa(versoes: 1, questoes: 1, tamEnunciado: 5, tamAlt: 5),
      )..['criadoEm'] = '2026-03-04T10:00:00.000';
      final p = ProvaMapper.provaDeMapa('x', mapa, versoes: const []);
      expect(p.criadoEm, DateTime(2026, 3, 4, 10));
    });
  });

  group('Estimativa de tamanho (turma de 40 alunos = 40 versões)', () {
    const alvo = 500 * 1024; // folga confortável abaixo do limite

    int tudoNoDocumento(ProvaGerada p) =>
        tamanhoFirestore(ProvaMapper.provaParaMapa(p)) +
        tamanhoFirestore([
          for (final v in p.versoes) ProvaMapper.versaoParaMapa(v),
        ]);

    int maiorDocumentoComSubcolecao(ProvaGerada p) => [
      tamanhoFirestore(ProvaMapper.provaParaMapa(p)),
      for (final v in p.versoes)
        tamanhoFirestore(ProvaMapper.versaoParaMapa(v)),
    ].reduce(max);

    final cenarios = {
      'curta (20 questões, enunciado 100, alternativa 30)': provaFalsa(
        versoes: 40,
        questoes: 20,
        tamEnunciado: 100,
        tamAlt: 30,
      ),
      'média (30 questões, enunciado 200, alternativa 60)': provaFalsa(
        versoes: 40,
        questoes: 30,
        tamEnunciado: 200,
        tamAlt: 60,
      ),
      'longa (40 questões, enunciado 300, alternativa 80)': provaFalsa(
        versoes: 40,
        questoes: 40,
        tamEnunciado: 300,
        tamAlt: 80,
      ),
    };

    cenarios.forEach((nome, prova) {
      test('prova $nome', () {
        final maiorSub = maiorDocumentoComSubcolecao(prova);
        expect(maiorSub, lessThan(alvo));
      });
    });

    test('lista no documento estoura ~500 KB nos cenários médio e longo', () {
      expect(tudoNoDocumento(cenarios.values.elementAt(1)), greaterThan(alvo));
      expect(tudoNoDocumento(cenarios.values.elementAt(2)), greaterThan(alvo));
    });
  });
}
