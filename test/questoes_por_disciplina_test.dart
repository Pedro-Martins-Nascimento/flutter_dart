import 'package:flutter/material.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/screens/questoes/disciplinas_questoes_screen.dart';
import 'package:flutter_dart/screens/questoes/questoes_disciplina_screen.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  Questao questao(String id, String grupo) => Questao(
    id: id,
    materiaId: grupo,
    enunciado: 'Questão $id',
    alternativas: ['A', 'B'],
    respostaCorreta: 0,
  );

  // Questões novas ficam direto na disciplina (q1, q2 em Matemática). As
  // antigas apontam para uma matéria: q3 está numa matéria que foi para
  // Física; q4 está numa matéria sem disciplina.
  late QuestoesRepository questoes;
  late TurmasRepository disciplinas;

  setUp(() {
    questoes = QuestoesRepository(
      materias: [
        Materia(id: 'mFis', nome: 'Mecânica', disciplinaId: 'd2'),
        Materia(id: 'mSolta', nome: 'Antiga'),
      ],
      questoes: [
        questao('q1', 'd1'),
        questao('q2', 'd1'),
        questao('q3', 'mFis'),
        questao('q4', 'mSolta'),
      ],
    );
    disciplinas = TurmasRepository(
      iniciais: [
        Disciplina(id: 'd1', nome: 'Matemática'),
        Disciplina(id: 'd2', nome: 'Física'),
      ],
    );
  });

  group('repositório', () {
    test('questões novas e antigas caem na disciplina certa', () {
      List<String> ids(String? disciplinaId) => [
        for (final q in questoes.questoesDaDisciplina(disciplinaId)) q.id,
      ];
      expect(ids('d1'), ['q1', 'q2']);
      expect(ids('d2'), ['q3']);
      expect(ids(null), ['q4']);
    });

    test('mover questão sem disciplina leva ela para a disciplina', () async {
      await questoes.moverQuestao('q4', 'd2');
      expect(questoes.questoesDaDisciplina(null), isEmpty);
      expect(
        questoes.questoesDaDisciplina('d2').map((q) => q.id),
        containsAll(['q3', 'q4']),
      );
    });
  });

  group('telas', () {
    Future<void> abrir(WidgetTester tester, String local) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: local,
        routes: [
          GoRoute(
            path: '/questoes',
            builder: (_, _) => const DisciplinasQuestoesScreen(),
            routes: [
              GoRoute(
                path: 'disciplina/:disciplinaId',
                builder: (_, state) => QuestoesDisciplinaScreen(
                  disciplinaId: state.pathParameters['disciplinaId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'questao',
                    builder: (_, state) => Text(
                      'formulário de ${state.pathParameters['disciplinaId']}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: questoes),
            ChangeNotifierProvider.value(value: disciplinas),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a raiz lista as disciplinas, sem matérias', (tester) async {
      await abrir(tester, '/questoes');

      expect(find.text('Matemática'), findsOneWidget);
      expect(find.text('2 questões'), findsOneWidget);
      expect(find.text('Física'), findsOneWidget);
      expect(find.text('1 questão'), findsOneWidget);
      expect(find.text('Sem disciplina'), findsOneWidget);
      // Nomes de matérias não aparecem.
      expect(find.text('Mecânica'), findsNothing);
    });

    testWidgets('a disciplina mostra as questões dela direto', (tester) async {
      await abrir(tester, '/questoes');

      await tester.tap(find.text('Matemática'));
      await tester.pumpAndSettle();

      expect(find.text('Questão q1'), findsOneWidget);
      expect(find.text('Questão q2'), findsOneWidget);
      expect(find.text('Questão q3'), findsNothing);

      // "+ Questão" abre o formulário dentro da disciplina.
      await tester.tap(find.text('+ Questão'));
      await tester.pumpAndSettle();
      expect(find.text('formulário de d1'), findsOneWidget);
    });

    testWidgets('questão sem disciplina pode ser movida para uma', (
      tester,
    ) async {
      await abrir(tester, '/questoes/disciplina/$semDisciplina');

      expect(find.text('Questão q4'), findsOneWidget);
      // No grupo "Sem disciplina" não se cria questão.
      expect(find.text('+ Questão'), findsNothing);

      await tester.tap(find.text('Mover para disciplina'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matemática'));
      await tester.pumpAndSettle();

      expect(questoes.disciplinaDoGrupo('d1'), 'd1');
      expect(
        questoes.questoesDaDisciplina('d1').map((q) => q.id),
        contains('q4'),
      );
      expect(find.text('Questão q4'), findsNothing);
    });
  });
}
