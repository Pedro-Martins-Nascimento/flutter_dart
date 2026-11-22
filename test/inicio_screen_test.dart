import 'package:flutter/material.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/screens/inicio/inicio_screen.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/provas_exemplo.dart';

import 'package:provider/provider.dart';

import 'correcao_fixtures.dart';
import 'prova_repository_contrato.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester, {
    required ProvaRepositoryMemoria provas,
    required CorrecaoRepositoryMemoria correcoes,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TurmasRepository(iniciais: const []),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                QuestoesRepository(materias: materiasMock, questoes: const []),
          ),
        ],
        child: MaterialApp(
          home: InicioScreen(repository: provas, correcoes: correcoes),
        ),
      ),
    );
    await tester.pump();
  }

  // O _Numero é uma coluna com o rótulo em cima e o valor embaixo.
  String valorDe(WidgetTester tester, String rotulo) {
    final coluna = tester
        .element(find.text(rotulo))
        .findAncestorWidgetOfExactType<Column>()!;
    return coluna.children.whereType<Text>().toList()[1].data!;
  }

  testWidgets('sem correções: zeros, média vazia e aviso no erro por matéria', (
    tester,
  ) async {
    await abrir(
      tester,
      provas: ProvaRepositoryMemoria(),
      correcoes: CorrecaoRepositoryMemoria(),
    );

    expect(valorDe(tester, 'Corrigidas'), '0');
    expect(valorDe(tester, 'Pendentes'), '0');
    // A média e as últimas provas saíram da tela inicial.
    expect(find.text('Média'), findsNothing);
    expect(find.text('ÚLTIMAS PROVAS'), findsNothing);
    expect(find.textContaining('Ainda não há correções'), findsOneWidget);
  });

  testWidgets('com correções: contagem, pendentes, média e erro por matéria', (
    tester,
  ) async {
    final provas = ProvaRepositoryMemoria();
    await provas.criar(prova('a', versoes: 4));
    final correcoes = CorrecaoRepositoryMemoria();
    // Nota 5 (acerta q1, erra q2) e nota 10 (acerta as duas), da matéria mat1.
    await correcoes.salvar(correcao('c1', provaId: 'a', versaoId: 'v1'));
    await correcoes.salvar(
      correcao(
        'c2',
        provaId: 'a',
        versaoId: 'v2',
        respostas: [resposta('q1', certa: true), resposta('q2', certa: true)],
      ),
    );

    await abrir(tester, provas: provas, correcoes: correcoes);

    expect(valorDe(tester, 'Corrigidas'), '2');
    expect(valorDe(tester, 'Pendentes'), '2');
    expect(find.text('Média'), findsNothing);
    // 3 acertos em 4 respostas de Matemática: 25% de erro.
    expect(find.text('25%'), findsOneWidget);
    expect(find.textContaining('Ainda não há correções'), findsNothing);
  });

  testWidgets('os números acompanham uma correção nova', (tester) async {
    final provas = ProvaRepositoryMemoria();
    await provas.criar(prova('a', versoes: 1));
    final correcoes = CorrecaoRepositoryMemoria();
    await abrir(tester, provas: provas, correcoes: correcoes);
    expect(valorDe(tester, 'Pendentes'), '1');

    await correcoes.salvar(correcao('c1', provaId: 'a', versaoId: 'v1'));
    await tester.pump();

    expect(valorDe(tester, 'Corrigidas'), '1');
    expect(valorDe(tester, 'Pendentes'), '0');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'o cartão de + cria uma disciplina, que aparece com o botão Nova turma',
    (tester) async {
      await abrir(
        tester,
        provas: ProvaRepositoryMemoria(),
        correcoes: CorrecaoRepositoryMemoria(),
      );

      final adicionar = find.text('Nova disciplina');
      await tester.ensureVisible(adicionar);
      expect(find.text('Nova turma'), findsNothing);

      await tester.tap(adicionar);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Física');
      await tester.pump();
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      expect(find.text('Física'), findsOneWidget);
      expect(find.text('Sem turmas'), findsOneWidget);
      expect(find.text('Nova turma'), findsOneWidget);
      // O cartão de + continua lá para criar outra.
      expect(find.text('Nova disciplina'), findsOneWidget);
    },
  );

  testWidgets('o botão Nova turma cria a turma dentro da disciplina', (
    tester,
  ) async {
    final turmas = TurmasRepository(
      iniciais: [Disciplina(id: 'd1', nome: 'Física')],
    );
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final aberta = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => InicioScreen(
            repository: ProvaRepositoryMemoria(),
            correcoes: CorrecaoRepositoryMemoria(),
          ),
        ),
        GoRoute(
          path: '/turmas/:id',
          builder: (_, state) {
            aberta.add(state.pathParameters['id']!);
            return const Text('tela da disciplina');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: turmas),
          ChangeNotifierProvider(
            create: (_) =>
                QuestoesRepository(materias: materiasMock, questoes: const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Nova turma'));
    await tester.tap(find.text('Nova turma'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2º ano A');
    await tester.pump();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(turmas.disciplinaPorId('d1')!.turmas.single.nome, '2º ano A');
    // Depois de criar, abre a disciplina para mostrar as turmas.
    expect(aberta, ['d1']);
    expect(find.text('tela da disciplina'), findsOneWidget);
  });
}
