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

    test('alunos: adicionar, editar e remover', () async {
      await repositorio.adicionarAlunos('t1', [
        AlunoTurma(id: 'a1', nome: 'Ana', matricula: '123'),
      ]);
      await repositorio.atualizarAluno(
        't1',
        AlunoTurma(id: 'a1', nome: 'Ana Lima', matricula: '456'),
      );

      final alunoAtualizado = repositorio.porId('t1')!.alunos.single;
      expect(alunoAtualizado.nome, 'Ana Lima');
      expect(alunoAtualizado.matricula, '456');
      expect(repositorio.porId('t1')!.qtdAlunos, 1);

      await repositorio.removerAluno('t1', 'a1');

      expect(repositorio.porId('t1')!.alunos, isEmpty);
      expect(notificacoes, 3);
    });

    test('caso de borda: turma recém-criada inicia sem alunos', () {
      final nova = repositorio.criar('Turma Vazia');
      expect(nova.alunos, isEmpty);
      expect(nova.qtdAlunos, 0);
    });

    test('caso de borda: importar lote de alunos preservando nome e matrícula', () async {
      final lote = [
        AlunoTurma(id: 'l1', nome: 'Aluno 1', matricula: 'M01'),
        AlunoTurma(id: 'l2', nome: 'Aluno 2', matricula: 'M02'),
      ];
      await repositorio.adicionarAlunos('t1', lote);

      expect(repositorio.porId('t1')!.alunos, hasLength(2));
      expect(repositorio.porId('t1')!.alunos[0].matricula, 'M01');
      expect(repositorio.porId('t1')!.alunos[1].matricula, 'M02');
    });

    test('caso de borda: operações em turma inexistente não geram exceções uncaught', () async {
      await repositorio.adicionarAlunos('inexistente', [
        AlunoTurma(id: 'x', nome: 'X', matricula: '0'),
      ]);
      await repositorio.atualizarAluno('inexistente', AlunoTurma(id: 'x', nome: 'X', matricula: '0'));
      await repositorio.removerAluno('inexistente', 'x');
      repositorio.excluir('inexistente');
      expect(repositorio.porId('inexistente'), isNull);
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

    test('criarMateria devolve a matéria criada', () {
      final materia = repositorio.criarMateria('Física');

      expect(repositorio.materiaPorId(materia.id)?.nome, 'Física');
    });
  });
}
