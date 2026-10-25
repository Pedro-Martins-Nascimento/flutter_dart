import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dart/models/correcao.dart';
import 'package:flutter_dart/screens/corrigir/corrigir_versao_screen.dart';
import 'package:flutter_dart/screens/corrigir/resultado_screen.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'prova_repository_contrato.dart';

/// Detecção simulada previsível: [valor] sempre, e a primeira alternativa
/// errada quando a tela sorteia um erro.
class _Aleatorio implements Random {
  _Aleatorio(this.valor);
  final double valor;

  @override
  bool nextBool() => true;
  @override
  double nextDouble() => valor;
  @override
  int nextInt(int max) => 0;
}

class _CorrecoesComFalha extends CorrecaoRepositoryMemoria {
  @override
  Future<void> salvar(Correcao correcao) async =>
      throw StateError('sem conexão');
}

void main() {
  Future<void> abrir(
    WidgetTester tester,
    CorrecaoRepositoryMemoria correcoes,
    Random random,
  ) async {
    final p = prova('a', versoes: 1);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => CorrigirVersaoScreen(
            prova: p,
            versao: p.versoes.first,
            correcoes: correcoes,
            random: random,
          ),
        ),
        GoRoute(
          path: '/corrigir/resultado',
          builder: (context, state) =>
              ResultadoScreen(correcao: state.extra! as Correcao),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TurmasRepository(iniciais: const []),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  testWidgets('confirmar salva a correção e abre o resultado', (tester) async {
    final correcoes = CorrecaoRepositoryMemoria();
    await abrir(tester, correcoes, _Aleatorio(0.99));

    await tester.tap(find.text('Confirmar correção'));
    await tester.pumpAndSettle();

    final salvas = await correcoes.listar();
    expect(salvas, hasLength(1));
    expect(salvas.single.provaId, 'a');
    expect(salvas.single.versaoId, 'v1');
    expect(salvas.single.nota, 10);
    expect(find.text('Resultado'), findsOneWidget);
    expect(find.text('10.0'), findsOneWidget);
  });

  testWidgets('alternativa não identificada trava a confirmação até escolher', (
    tester,
  ) async {
    final correcoes = CorrecaoRepositoryMemoria();
    await abrir(tester, correcoes, _Aleatorio(0.05));

    ElevatedButton botao() => tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Confirmar correção'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(botao().onPressed, isNull);
    expect(find.textContaining('Selecione manualmente'), findsOneWidget);

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(botao().onPressed, isNotNull);

    await tester.tap(find.text('Confirmar correção'));
    await tester.pumpAndSettle();

    // A resposta certa da questão é a B; marcar a A dá nota 0.
    expect((await correcoes.listar()).single.nota, 0);
  });

  testWidgets('erro ao salvar avisa e continua na tela', (tester) async {
    await abrir(tester, _CorrecoesComFalha(), _Aleatorio(0.99));

    await tester.tap(find.text('Confirmar correção'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível salvar a correção.'), findsOneWidget);
    expect(find.text('Resultado'), findsNothing);
  });
}
