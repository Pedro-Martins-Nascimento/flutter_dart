import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';

void main() {
  group('TurmasRepository', () {
    late TurmasRepository repositorio;
    late int notificacoes;

    setUp(() {
      repositorio = TurmasRepository(
        iniciais: [Turma(id: 't1', nome: 'Turma 1')],
      );
      notificacoes = 0;
      repositorio.addListener(() => notificacoes++);
    });

    test('criar coloca a turma no topo e avisa as telas', () {
      final nova = repositorio.criar('Turma nova');

      expect(repositorio.turmas.first.id, nova.id);
      expect(repositorio.turmas, hasLength(2));
      expect(notificacoes, 1);
    });

    test('excluir remove a turma', () {
      repositorio.excluir('t1');

      expect(repositorio.porId('t1'), isNull);
      expect(notificacoes, 1);
    });

    test('alunos: adicionar, editar e remover', () {
      repositorio.adicionarAlunos('t1', [
        AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1'),
      ]);
      repositorio.atualizarAluno(
        't1',
        AlunoTurma(id: 'a1', nome: 'Ana Lima', matricula: '1'),
      );

      expect(repositorio.porId('t1')!.alunos.single.nome, 'Ana Lima');
      expect(repositorio.porId('t1')!.qtdAlunos, 1);

      repositorio.removerAluno('t1', 'a1');

      expect(repositorio.porId('t1')!.alunos, isEmpty);
      expect(notificacoes, 3);
    });

    test('a lista exposta não pode ser alterada de fora', () {
      expect(
        () => repositorio.turmas.add(Turma(id: 'x', nome: 'x')),
        throwsUnsupportedError,
      );
    });
  });

  group('QuestoesRepository', () {
    late QuestoesRepository repositorio;

    Questao questao(String id, String materiaId) => Questao(
      id: id,
      materiaId: materiaId,
      enunciado: 'Enunciado $id',
      alternativas: const ['A', 'B'],
      respostaCorreta: 0,
    );

    setUp(() {
      repositorio = QuestoesRepository(
        materias: [Materia(id: 'm1', nome: 'Matemática')],
        questoes: [questao('q1', 'm1')],
      );
    });

    test('salvarQuestao cria uma nova ou substitui a existente', () {
      repositorio.salvarQuestao(questao('q2', 'm1'));
      repositorio.salvarQuestao(
        Questao(
          id: 'q1',
          materiaId: 'm1',
          enunciado: 'Editada',
          alternativas: const ['A', 'B'],
          respostaCorreta: 1,
        ),
      );

      final questoes = repositorio.questoesDaMateria('m1');
      expect(questoes, hasLength(2));
      expect(questoes.firstWhere((q) => q.id == 'q1').enunciado, 'Editada');
    });

    test('excluirMateria leva junto as questões dela', () {
      repositorio.excluirMateria('m1');

      expect(repositorio.materias, isEmpty);
      expect(repositorio.questoes, isEmpty);
    });

    test('criarMateria e excluirQuestao', () {
      repositorio.criarMateria('História');
      repositorio.excluirQuestao('q1');

      expect(repositorio.materias.map((m) => m.nome), contains('História'));
      expect(repositorio.questoes, isEmpty);
    });
  });
}
