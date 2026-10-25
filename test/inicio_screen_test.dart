import 'package:flutter/material.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/screens/inicio/inicio_screen.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(valorDe(tester, 'Média'), '-');
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
    expect(valorDe(tester, 'Média'), '7,5');
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
}
