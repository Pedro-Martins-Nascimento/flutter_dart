import 'package:flutter/material.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/screens/inicio/estatistica_completa_screen.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'correcao_fixtures.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    CorrecaoRepositoryMemoria correcoes,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            QuestoesRepository(materias: materiasMock, questoes: const []),
        child: MaterialApp(
          home: EstatisticaCompletaScreen(correcoes: correcoes),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sem correções mostra o aviso', (tester) async {
    await abrir(tester, CorrecaoRepositoryMemoria());

    expect(find.textContaining('Nenhuma correção com nota'), findsOneWidget);
  });

  testWidgets('com correções mostra média, matéria, prova e ranking', (
    tester,
  ) async {
    final correcoes = CorrecaoRepositoryMemoria();
    // Ana tira 5 e Bruno tira 10, os dois na prova p1 e na matéria mat1.
    await correcoes.salvar(
      correcao('c1', alunoId: 'a1', alunoNome: 'Ana', versaoId: 'v1'),
    );
    await correcoes.salvar(
      correcao(
        'c2',
        alunoId: 'b1',
        alunoNome: 'Bruno',
        versaoId: 'v2',
        respostas: [resposta('q1', certa: true), resposta('q2', certa: true)],
      ),
    );

    await abrir(tester, correcoes);

    expect(find.text('7,5'), findsOneWidget);
    // 3 acertos em 4 respostas de Matemática.
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Prova p1'), findsOneWidget);
    expect(find.text('7.5 · 2 corrigida(s)'), findsOneWidget);
    expect(find.text('1º  Bruno'), findsOneWidget);
    expect(find.text('2º  Ana'), findsOneWidget);
    // A questão que mais derruba a turma é a q2 (1 acerto em 2).
    expect(find.text('Enunciado de q2'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('sem aluno vinculado o ranking avisa', (tester) async {
    final correcoes = CorrecaoRepositoryMemoria();
    await correcoes.salvar(correcao('c1'));

    await abrir(tester, correcoes);

    expect(
      find.text('Nenhuma correção com aluno vinculado ainda.'),
      findsOneWidget,
    );
  });
}
