import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';

void main() {
  group('TurmasRepository', () {
    late TurmasRepository repositorio;
    late int notificacoes;

    // Disciplina d1 com a turma t1 (vazia).
    setUp(() {
      repositorio = TurmasRepository(
        iniciais: [
          Disciplina(
            id: 'd1',
            nome: 'Matemática',
            turmas: [Turma(id: 't1', nome: 'Turma 1')],
          ),
        ],
      );
      notificacoes = 0;
      repositorio.addListener(() => notificacoes++);
    });

    List<AlunoTurma> alunosDeT1() =>
        repositorio.disciplinaPorId('d1')!.turmaPorId('t1')!.alunos;

    test('criar disciplina coloca no topo, sem turmas, e avisa as telas', () {
      final nova = repositorio.criarDisciplina('Física');

      expect(repositorio.disciplinas.first.id, nova.id);
      expect(repositorio.disciplinas, hasLength(2));
      expect(nova.turmas, isEmpty);
      expect(notificacoes, 1);
    });

    test('excluir disciplina remove ela e as turmas', () {
      repositorio.excluirDisciplina('d1');

      expect(repositorio.disciplinaPorId('d1'), isNull);
      expect(notificacoes, 1);
    });

    test('criar e excluir turma dentro da disciplina', () async {
      final nova = await repositorio.criarTurma('d1', '3º ano B');

      final disciplina = repositorio.disciplinaPorId('d1')!;
      expect(disciplina.turmas.map((t) => t.nome), ['Turma 1', '3º ano B']);
      expect(nova!.alunos, isEmpty);

      await repositorio.excluirTurma('d1', nova.id);
      expect(repositorio.disciplinaPorId('d1')!.turmas, hasLength(1));
      expect(notificacoes, 2);
    });

    test('alunos: adicionar, editar e remover dentro da turma', () async {
      await repositorio.adicionarAlunos('d1', 't1', [
        AlunoTurma(id: 'a1', nome: 'Ana', matricula: '123'),
      ]);
      await repositorio.atualizarAluno(
        'd1',
        't1',
        AlunoTurma(id: 'a1', nome: 'Ana Lima', matricula: '456'),
      );

      final alunoAtualizado = alunosDeT1().single;
      expect(alunoAtualizado.nome, 'Ana Lima');
      expect(alunoAtualizado.matricula, '456');
      expect(repositorio.disciplinaPorId('d1')!.qtdAlunos, 1);

      await repositorio.removerAluno('d1', 't1', 'a1');

      expect(alunosDeT1(), isEmpty);
      expect(notificacoes, 3);
    });

    test('importar lote de alunos preserva nome e matrícula', () async {
      await repositorio.adicionarAlunos('d1', 't1', [
        AlunoTurma(id: 'l1', nome: 'Aluno 1', matricula: 'M01'),
        AlunoTurma(id: 'l2', nome: 'Aluno 2', matricula: 'M02'),
      ]);

      expect(alunosDeT1(), hasLength(2));
      expect(alunosDeT1()[0].matricula, 'M01');
      expect(alunosDeT1()[1].matricula, 'M02');
    });

    test('operações em disciplina ou turma inexistente não falham', () async {
      final aluno = AlunoTurma(id: 'x', nome: 'X', matricula: '0');
      await repositorio.adicionarAlunos('inexistente', 't1', [aluno]);
      await repositorio.adicionarAlunos('d1', 'inexistente', [aluno]);
      await repositorio.atualizarAluno('d1', 'inexistente', aluno);
      await repositorio.removerAluno('inexistente', 't1', 'x');
      expect(await repositorio.criarTurma('inexistente', 'X'), isNull);
      await repositorio.excluirTurma('inexistente', 't1');
      repositorio.excluirDisciplina('inexistente');
      expect(alunosDeT1(), isEmpty);
      expect(notificacoes, 0);
    });

    test('a lista exposta não pode ser alterada de fora', () {
      expect(
        () => repositorio.disciplinas.add(Disciplina(id: 'x', nome: 'x')),
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
