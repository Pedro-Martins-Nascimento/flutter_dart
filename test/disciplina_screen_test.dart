import 'package:flutter/material.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/screens/turmas/disciplina_screen.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  late TurmasRepository turmas;
  late List<String> abertas;

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    turmas = TurmasRepository(
      iniciais: [
        Disciplina(
          id: 'd1',
          nome: 'Matemática',
          turmas: [
            Turma(
              id: 't1',
              nome: '3º ano A',
              alunos: [AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1')],
            ),
          ],
        ),
      ],
    );
    abertas = [];
    final router = GoRouter(
      initialLocation: '/turmas/d1',
      routes: [
        GoRoute(
          path: '/turmas/:id',
          builder: (_, state) =>
              DisciplinaScreen(disciplinaId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'turma/:turmaId',
              builder: (_, state) {
                abertas.add(state.pathParameters['turmaId']!);
                return const Text('tela da turma');
              },
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: turmas,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o + e um quadradinho por turma', (tester) async {
    await abrir(tester);

    expect(find.text('Matemática'), findsOneWidget);
    expect(find.text('Nova turma'), findsOneWidget);
    expect(find.text('3º ano A'), findsOneWidget);
    expect(find.text('1 aluno'), findsOneWidget);
  });

  testWidgets('o + cria uma turma, que aparece ao lado', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Nova turma'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3º ano B');
    await tester.pump();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('3º ano B'), findsOneWidget);
    expect(find.text('Sem alunos'), findsOneWidget);
    expect(turmas.disciplinaPorId('d1')!.turmas.map((t) => t.nome), [
      '3º ano A',
      '3º ano B',
    ]);
  });

  testWidgets('tocar na turma abre a tela dela', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('3º ano A'));
    await tester.pumpAndSettle();

    expect(abertas, ['t1']);
    expect(find.text('tela da turma'), findsOneWidget);
  });
}
