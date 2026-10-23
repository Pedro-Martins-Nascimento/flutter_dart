import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/services/notas_da_prova.dart';
import 'package:flutter_dart/services/prova_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';

void main() {
  final prova = ProvaResumo(
    id: 'p1',
    nome: 'Prova 1',
    materia: 'Matemática',
    turma: 'Turma A',
    criadoEm: DateTime(2026, 5, 10),
    totalVersoes: 2,
  );
  final turmas = [
    Turma(
      id: 't1',
      nome: 'Turma A',
      alunos: [
        AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1'),
        AlunoTurma(id: 'b1', nome: 'Bruno', matricula: '2'),
      ],
    ),
    Turma(
      id: 't2',
      nome: 'Turma B',
      alunos: [AlunoTurma(id: 'c1', nome: 'Carla', matricula: '3')],
    ),
  ];

  test('uma linha por aluno da turma, na ordem da turma', () {
    final linhas = linhasDeNotas(
      prova: prova,
      turmas: turmas,
      correcoes: [correcao('x', alunoId: 'b1', alunoNome: 'Bruno')],
    );

    expect(linhas.map((l) => l.aluno), ['Ana', 'Bruno']);
    expect(linhas[0].nota, isNull);
    expect(linhas[1].nota, 5);
    expect(linhas.every((l) => l.prova == 'Prova 1'), isTrue);
  });

  test('ignora correções de outras provas', () {
    final linhas = linhasDeNotas(
      prova: prova,
      turmas: turmas,
      correcoes: [correcao('x', provaId: 'outra', alunoId: 'a1')],
    );

    expect(linhas.first.nota, isNull);
  });

  test('aluno com mais de uma correção fica com a mais recente', () {
    final linhas = linhasDeNotas(
      prova: prova,
      turmas: turmas,
      correcoes: [
        correcao(
          'velha',
          alunoId: 'a1',
          diasAtras: 5,
          respostas: [resposta('q1', certa: false)],
        ),
        correcao(
          'nova',
          alunoId: 'a1',
          respostas: [resposta('q1', certa: true)],
        ),
      ],
    );

    expect(linhas.first.nota, 10);
  });

  test('quem não está na turma e folha sem aluno entram no fim', () {
    final linhas = linhasDeNotas(
      prova: prova,
      turmas: turmas,
      correcoes: [
        correcao('x', versaoId: 'v7', alunoId: 'fora', alunoNome: 'Diego'),
        correcao('y', versaoId: 'v3'),
      ],
    );

    expect(linhas.map((l) => l.aluno), [
      'Ana',
      'Bruno',
      'Diego',
      'Sem aluno vinculado (v3)',
    ]);
  });

  test('prova sem turma usa só as correções', () {
    final semTurma = ProvaResumo(
      id: 'p1',
      nome: 'Prova 1',
      materia: 'Matemática',
      turma: null,
      criadoEm: DateTime(2026, 5, 10),
      totalVersoes: 1,
    );
    final linhas = linhasDeNotas(
      prova: semTurma,
      turmas: turmas,
      correcoes: [correcao('x', alunoId: 'a1', alunoNome: 'Ana')],
    );

    expect(linhas.map((l) => l.aluno), ['Ana']);
  });

  test('sem alunos e sem correções não há linhas', () {
    final linhas = linhasDeNotas(
      prova: prova,
      turmas: const [],
      correcoes: const [],
    );

    expect(linhas, isEmpty);
  });
}
