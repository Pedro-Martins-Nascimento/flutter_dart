import 'package:flutter/material.dart';
import 'package:flutter_dart/screens/corrigir/historico_correcoes_screen.dart';
import 'package:flutter_dart/screens/corrigir/resultado_screen.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';

void main() {
  testWidgets('resultado mostra nota, acertos e o gabarito por questão', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultadoScreen(
          correcao: correcao('c1', alunoId: 'a1', alunoNome: 'Ana'),
        ),
      ),
    );

    expect(find.textContaining('Ana'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.textContaining('Enunciado de q1'), findsOneWidget);
    expect(find.textContaining('Enunciado de q2'), findsOneWidget);
  });

  testWidgets('resultado oferece o boletim em PDF', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ResultadoScreen(correcao: correcao('c1'))),
    );

    expect(find.text('Exportar boletim (PDF)'), findsOneWidget);
  });

  testWidgets('resultado sem aluno vinculado avisa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ResultadoScreen(correcao: correcao('c1'))),
    );

    expect(find.textContaining('Sem aluno vinculado'), findsOneWidget);
  });

  testWidgets('histórico vazio mostra o aviso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HistoricoCorrecoesScreen(correcoes: CorrecaoRepositoryMemoria()),
      ),
    );
    await tester.pump();

    expect(
      find.text('Nenhuma folha com nota calculada ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('histórico só oferece os boletins quando há correções', (
    tester,
  ) async {
    final correcoes = CorrecaoRepositoryMemoria();
    await tester.pumpWidget(
      MaterialApp(home: HistoricoCorrecoesScreen(correcoes: correcoes)),
    );
    await tester.pump();
    expect(find.byTooltip('Exportar boletins de todos (PDF)'), findsNothing);

    await correcoes.salvar(correcao('c1'));
    await tester.pump();

    expect(find.byTooltip('Exportar boletins de todos (PDF)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('histórico lista as correções e acompanha as novas', (
    tester,
  ) async {
    final correcoes = CorrecaoRepositoryMemoria();
    await correcoes.salvar(correcao('c1', alunoNome: 'Ana'));
    await tester.pumpWidget(
      MaterialApp(home: HistoricoCorrecoesScreen(correcoes: correcoes)),
    );
    await tester.pump();

    expect(find.textContaining('Nota 5.0'), findsOneWidget);
    expect(find.textContaining('Ana'), findsOneWidget);

    await correcoes.salvar(correcao('c2', alunoNome: 'Bruno', diasAtras: 1));
    await tester.pump();

    expect(find.textContaining('Bruno'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
