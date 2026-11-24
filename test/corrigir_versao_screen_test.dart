import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dart/models/correcao.dart';
import 'package:flutter_dart/screens/corrigir/corrigir_versao_screen.dart';
import 'package:flutter_dart/screens/corrigir/resultado_screen.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/leitor_omr.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import 'helpers/foto_cartao.dart';

import 'prova_repository_contrato.dart';

final _foto = Uint8List.fromList([1, 2, 3]);

/// Leitor falso: devolve a leitura da questão 1 com estas notas por bolinha
/// (A, B, C, D), aplicando a regra de verdade.
LerGabarito _leitor(List<double> preenchimento) =>
    (foto, alternativas) async =>
        LeituraCartao([LeituraQuestao.dePreenchimento(0, preenchimento)]);

/// X na B (a certa).
final _xNaB = _leitor(const [0.02, 0.95, 0.03, 0.02]);

class _CorrecoesComFalha extends CorrecaoRepositoryMemoria {
  @override
  Future<void> salvar(Correcao correcao) async =>
      throw StateError('sem conexão');
}

void main() {
  Future<void> abrir(
    WidgetTester tester,
    CorrecaoRepositoryMemoria correcoes, {
    LerGabarito? ler,
    Uint8List? foto,
  }) async {
    final p = prova('a', versoes: 1);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => CorrigirVersaoScreen(
            prova: p,
            versao: p.versoes.first,
            correcoes: correcoes,
            foto: foto ?? (ler == null ? null : _foto),
            lerGabarito: ler ?? _xNaB,
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

  ElevatedButton botao(WidgetTester tester) => tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Confirmar correção'),
      matching: find.byType(ElevatedButton),
    ),
  );

  testWidgets('a leitura da foto preenche a resposta e confirma', (
    tester,
  ) async {
    final correcoes = CorrecaoRepositoryMemoria();
    await abrir(tester, correcoes, ler: _xNaB);

    expect(find.byKey(const ValueKey('motivo_0')), findsNothing);
    expect(botao(tester).onPressed, isNotNull);

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

  testWidgets('marcação dupla vai para o professor escolher', (tester) async {
    final correcoes = CorrecaoRepositoryMemoria();
    await abrir(tester, correcoes, ler: _leitor(const [0.9, 0.95, 0.03, 0.02]));

    expect(botao(tester).onPressed, isNull);
    expect(find.text(SituacaoQuestao.dupla.mensagem), findsOneWidget);

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(botao(tester).onPressed, isNotNull);
    // Continua mostrando que a resposta foi conferida pelo professor.
    expect(
      find.text('Conferida: ${SituacaoQuestao.dupla.mensagem}'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirmar correção'));
    await tester.pumpAndSettle();

    // A resposta certa da questão é a B; marcar a A dá nota 0.
    expect((await correcoes.listar()).single.nota, 0);
  });

  testWidgets('em branco e rasura também ficam para revisão', (tester) async {
    for (final (notas, situacao) in [
      (const [0.02, 0.03, 0.02, 0.01], SituacaoQuestao.emBranco),
      (const [0.02, 0.4, 0.02, 0.01], SituacaoQuestao.rasura),
    ]) {
      await abrir(tester, CorrecaoRepositoryMemoria(), ler: _leitor(notas));
      expect(find.text(situacao.mensagem), findsOneWidget);
      expect(botao(tester).onPressed, isNull);
    }
  });

  testWidgets('foto ilegível avisa e deixa marcar na mão', (tester) async {
    await abrir(
      tester,
      CorrecaoRepositoryMemoria(),
      ler: (foto, alternativas) async =>
          throw const LeituraOmrException(ProblemaLeitura.marcadores),
    );

    expect(
      find.textContaining(ProblemaLeitura.marcadores.mensagem),
      findsOneWidget,
    );
    expect(find.textContaining('Selecione manualmente'), findsOneWidget);
    expect(botao(tester).onPressed, isNull);
  });

  testWidgets('sem foto (web) o professor marca tudo na mão', (tester) async {
    await abrir(tester, CorrecaoRepositoryMemoria());
    expect(find.textContaining('não é lida automaticamente'), findsOneWidget);
    expect(botao(tester).onPressed, isNull);
  });

  testWidgets('questão fora da primeira página fica para o professor', (
    tester,
  ) async {
    await abrir(
      tester,
      CorrecaoRepositoryMemoria(),
      ler: (foto, alternativas) async => const LeituraCartao([]),
    );
    expect(find.textContaining('outra página do gabarito'), findsOneWidget);
    expect(botao(tester).onPressed, isNull);
  });

  testWidgets('erro ao salvar avisa e continua na tela', (tester) async {
    await abrir(tester, _CorrecoesComFalha(), ler: _xNaB);

    await tester.tap(find.text('Confirmar correção'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível salvar a correção.'), findsOneWidget);
    expect(find.text('Resultado'), findsNothing);
  });

  test('o leitor padrão lê a foto do gabarito de verdade', () async {
    // Questão 1 com X na B e questão 2 com duas marcações.
    final pagina = paginaGabarito(
      const [4, 4],
      {(0, 1): Marca.x, (1, 0): Marca.x, (1, 2): Marca.x},
    );
    const largura = 1200, altura = 1700;
    final foto = fotografar(
      pagina,
      largura: largura,
      altura: altura,
      cantos: cantosDeFrente(largura, altura),
    );
    final leitura = await lerGabaritoEmSegundoPlano(img.encodeJpg(foto), const [
      4,
      4,
    ]);
    expect(leitura.marcadas, [1, null]);
    expect(leitura.leituras[1].situacao, SituacaoQuestao.dupla);
    expect(leitura.paraRevisar, [1]);
  });
}
