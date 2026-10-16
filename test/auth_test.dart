import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/main.dart';
import 'package:flutter_dart/services/auth_service.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester, MockFirebaseAuth firebase) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyApp(
        auth: AuthService(auth: firebase),
        provas: ProvaRepositoryMemoria.comMocks(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> preencherLogin(WidgetTester tester) async {
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'prof@escola.com');
    await tester.enterText(campos.at(1), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('login com e-mail leva para o Início', (tester) async {
    await abrirApp(tester, MockFirebaseAuth());

    await preencherLogin(tester);

    expect(find.byTooltip('Sair'), findsOneWidget);
  });

  testWidgets('senha errada mostra mensagem e continua no login', (
    tester,
  ) async {
    final firebase = MockFirebaseAuth();
    whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
        .on(firebase)
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await abrirApp(tester, firebase);

    await preencherLogin(tester);

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  testWidgets('login com Google leva para o Início', (tester) async {
    await abrirApp(tester, MockFirebaseAuth());

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sair'), findsOneWidget);
  });

  testWidgets('sair volta para o login', (tester) async {
    await abrirApp(tester, MockFirebaseAuth(signedIn: true));
    expect(find.byTooltip('Sair'), findsOneWidget);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar com Google'), findsOneWidget);
  });
}
