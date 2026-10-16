import 'package:flutter_dart/services/estatistica_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';

void main() {
  group('mediaGeral', () {
    test('sem correções é 0', () {
      expect(EstatisticaService.mediaGeral([]), 0);
    });

    test('é a média das notas', () {
      final c = [
        correcao(
          'a',
          respostas: [resposta('q1', certa: true), resposta('q2', certa: true)],
        ), // 10
        correcao(
          'b',
          respostas: [
            resposta('q1', certa: false),
            resposta('q2', certa: false),
          ],
        ), // 0
        correcao('c'), // 5
      ];
      expect(EstatisticaService.mediaGeral(c), 5);
    });
  });

  group('percentualAcertoPorMateria', () {
    test('agrega as respostas de todas as correções por matéria', () {
      final c = [
        correcao(
          'a',
          respostas: [
            resposta('q1', certa: true, materiaId: 'mat1'),
            resposta('q2', certa: false, materiaId: 'mat2'),
          ],
        ),
        correcao(
          'b',
          respostas: [
            resposta('q1', certa: false, materiaId: 'mat1'),
            resposta('q2', certa: false, materiaId: 'mat2'),
          ],
        ),
      ];
      final r = EstatisticaService.percentualAcertoPorMateria(c);
      expect(r['mat1'], 50);
      expect(r['mat2'], 0);
    });

    test('sem correções devolve vazio', () {
      expect(EstatisticaService.percentualAcertoPorMateria([]), isEmpty);
    });
  });

  group('percentualAcertoPorQuestao', () {
    test('ordena da questão que mais derruba a turma para a que menos', () {
      final c = [
        correcao(
          'a',
          respostas: [
            resposta('facil', certa: true),
            resposta('dificil', certa: false),
          ],
        ),
        correcao(
          'b',
          respostas: [
            resposta('facil', certa: true),
            resposta('dificil', certa: false),
          ],
        ),
        correcao(
          'c',
          respostas: [
            resposta('facil', certa: false),
            resposta('dificil', certa: true),
          ],
        ),
      ];
      final r = EstatisticaService.percentualAcertoPorQuestao(c);

      expect(r.map((q) => q.questaoId), ['dificil', 'facil']);
      expect(r.first.percentual, closeTo(100 / 3, 1e-9));
      expect(r.last.percentual, closeTo(200 / 3, 1e-9));
      expect(r.first.respostas, 3);
      expect(r.first.enunciado, 'Enunciado de dificil');
    });

    test('empate fica em ordem alfabética do enunciado', () {
      final c = [
        correcao(
          'a',
          respostas: [resposta('qb', certa: true), resposta('qa', certa: true)],
        ),
      ];
      final r = EstatisticaService.percentualAcertoPorQuestao(c);
      expect(r.map((q) => q.questaoId), ['qa', 'qb']);
    });
  });

  group('rankingAlunos', () {
    test('ordena pela média e ignora correções sem aluno', () {
      final cheia = [resposta('q1', certa: true), resposta('q2', certa: true)];
      final c = [
        correcao(
          'a',
          alunoId: 'al1',
          alunoNome: 'Bruno',
          respostas: cheia,
        ), // 10
        correcao('b', alunoId: 'al2', alunoNome: 'Carla'), // 5
        correcao(
          'c',
          alunoId: 'al2',
          alunoNome: 'Carla',
          respostas: cheia,
        ), // 10
        correcao('d'), // sem aluno
      ];
      final r = EstatisticaService.rankingAlunos(c);

      expect(r.map((a) => a.aluno), ['Bruno', 'Carla']);
      expect(r.first.media, 10);
      expect(r.last.media, 7.5);
      expect(r.last.quantidade, 2);
    });

    test('empate de média desempata por nome', () {
      final c = [
        correcao('a', alunoId: 'al2', alunoNome: 'Carla'),
        correcao('b', alunoId: 'al1', alunoNome: 'Bruno'),
      ];
      expect(EstatisticaService.rankingAlunos(c).map((a) => a.aluno), [
        'Bruno',
        'Carla',
      ]);
    });

    test('sem id, agrupa pelo nome', () {
      final c = [
        correcao('a', alunoNome: 'Bruno'),
        correcao('b', alunoNome: 'Bruno'),
      ];
      final r = EstatisticaService.rankingAlunos(c);
      expect(r, hasLength(1));
      expect(r.single.quantidade, 2);
    });
  });

  test('porProva agrupa pelo id da prova', () {
    final c = [
      correcao('a', provaId: 'p1'),
      correcao('b', provaId: 'p2'),
      correcao('c', provaId: 'p1'),
    ];
    final r = EstatisticaService.porProva(c);
    expect(r.keys, ['p1', 'p2']);
    expect(r['p1']!.map((x) => x.id), ['a', 'c']);
  });
}
