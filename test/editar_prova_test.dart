import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dart/models/correcao.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/router/app_router.dart';
import 'package:flutter_dart/services/auth_service.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    ProvaRepositoryMemoria provas,
    CorrecaoRepositoryMemoria correcoes,
  ) async {
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = AuthService(
      auth: MockFirebaseAuth(signedIn: true),
      tokenGoogle: () async => 'x',
    );
    final router = criarRouter(auth, provas, correcoes);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(
            create: (_) => TurmasRepository(iniciais: turmasMock),
          ),
          ChangeNotifierProvider(
            create: (_) => QuestoesRepository(
              materias: materiasMock,
              questoes: questoesMock,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/provas-geradas');
    await tester.pumpAndSettle();
  }

  Future<void> tocarEditar(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Opções da prova').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar prova'));
    await tester.pumpAndSettle();
  }

  testWidgets('sem correções, edita tudo e regrava no mesmo registro', (
    tester,
  ) async {
    final provas = ProvaRepositoryMemoria.comMocks();
    final original = (await provas.listar()).first;
    await abrir(tester, provas, CorrecaoRepositoryMemoria());

    await tocarEditar(tester);

    expect(find.text('Editar prova'), findsOneWidget);
    expect(find.textContaining('deixam de valer'), findsOneWidget);
    final nome = find.byType(TextField).first;
    expect(tester.widget<TextField>(nome).controller?.text, original.nome);

    await tester.enterText(nome, 'P1 — Matemática (revisada)');
    final gerar = find.textContaining(RegExp(r'^Gerar \d+ vers'));
    await tester.ensureVisible(gerar);
    await tester.tap(gerar);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar prova'));
    await tester.tap(find.text('Salvar prova'));
    await tester.pumpAndSettle();

    final lista = await provas.listar();
    expect(lista, hasLength(3));
    final editada = lista.firstWhere((p) => p.id == original.id);
    expect(editada.nome, 'P1 — Matemática (revisada)');
    expect(editada.criadoEm, original.criadoEm);
    expect(editada.totalVersoes, original.totalVersoes);
    expect(find.text('Prova atualizada.'), findsOneWidget);
  });

  testWidgets('com correção salva, só deixa renomear', (tester) async {
    final provas = ProvaRepositoryMemoria.comMocks();
    final original = (await provas.listar()).first;
    final completa = (await provas.buscar(original.id))!;
    final correcoes = CorrecaoRepositoryMemoria();
    await correcoes.salvar(
      Correcao(
        id: 'c1',
        provaId: original.id,
        versaoId: completa.versoes.first.id,
        provaNome: original.nome,
        materia: original.materia,
        turma: original.turma,
        alunoId: null,
        alunoNome: null,
        corrigidoEm: DateTime(2026, 11, 1),
        respostas: const [],
      ),
    );
    await abrir(tester, provas, correcoes);

    await tocarEditar(tester);

    expect(find.text('Renomear prova'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'P1 renomeada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final editada = (await provas.buscar(original.id))!;
    expect(editada.nome, 'P1 renomeada');
    expect(editada.versoes.map((v) => v.qrCode), [
      for (final v in completa.versoes) v.qrCode,
    ]);
    expect(editada.versoes.first.provaNome, 'P1 renomeada');
    expect(find.text('Prova renomeada.'), findsOneWidget);
  });
}
