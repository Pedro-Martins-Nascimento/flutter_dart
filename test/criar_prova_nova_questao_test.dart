import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/router/app_router.dart';
import 'package:flutter_dart/services/auth_service.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('cria questão sem sair da tela de nova prova', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = AuthService(
      auth: MockFirebaseAuth(signedIn: true),
      tokenGoogle: () async => 'x',
    );
    final questoes = QuestoesRepository(
      materias: [Materia(id: 'fis', nome: 'Física')],
      questoes: const [],
    );
    final router = criarRouter(
      auth,
      ProvaRepositoryMemoria(),
      CorrecaoRepositoryMemoria(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(
            create: (_) => TurmasRepository(iniciais: const []),
          ),
          ChangeNotifierProvider.value(value: questoes),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/criar-prova');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Prova de Física');
    await tester.tap(find.text('Física'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ainda não há questões em Física'), findsOne);

    await tester.tap(find.text('Nova questão em Física'));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Quanto vale a gravidade?');
    for (var i = 1; i < tester.widgetList(campos).length; i++) {
      await tester.enterText(campos.at(i), 'Alternativa $i');
    }
    await tester.ensureVisible(find.text('Salvar questão'));
    await tester.tap(find.text('Salvar questão'));
    await tester.pumpAndSettle();

    expect(find.text('Quanto vale a gravidade?'), findsOneWidget);
    expect(find.textContaining('Ainda não há questões'), findsNothing);
    final nome = tester.widget<TextField>(find.byType(TextField).first);
    expect(nome.controller?.text, 'Prova de Física');
  });
}
