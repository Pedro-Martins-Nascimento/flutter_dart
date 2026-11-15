import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/provas_exemplo.dart';

import 'package:flutter_dart/main.dart';
import 'package:flutter_dart/services/auth_service.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester, MockFirebaseAuth firebase) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repoProvas = await criarProvaRepositoryMemoriaComMocks();
    await tester.pumpWidget(
      MyApp(
        auth: AuthService(
          auth: firebase,
          tokenGoogle: () async => 'id-token-falso',
        ),
        provas: repoProvas,
        correcoes: CorrecaoRepositoryMemoria(),
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

    expect(find.byTooltip('Conta'), findsOneWidget);
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

    expect(find.byTooltip('Conta'), findsOneWidget);
  });

  Future<void> preencherCadastro(
    WidgetTester tester, {
    String confirmacao = '123456',
  }) async {
    await tester.tap(find.widgetWithText(TextButton, 'Criar conta'));
    await tester.pumpAndSettle();
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Ana Souza');
    await tester.enterText(campos.at(1), 'ana@escola.com');
    await tester.enterText(campos.at(2), '123456');
    await tester.enterText(campos.at(3), confirmacao);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
    await tester.pumpAndSettle();
  }

  testWidgets('criar conta entra no app com o nome do professor', (
    tester,
  ) async {
    final firebase = MockFirebaseAuth();
    await abrirApp(tester, firebase);

    await preencherCadastro(tester);

    expect(find.byTooltip('Conta'), findsOneWidget);
    expect(firebase.currentUser?.email, 'ana@escola.com');
    expect(firebase.currentUser?.displayName, 'Ana Souza');
  });

  testWidgets('senhas diferentes não criam a conta', (tester) async {
    await abrirApp(tester, MockFirebaseAuth());

    await preencherCadastro(tester, confirmacao: '654321');

    expect(find.text('As senhas não conferem'), findsOneWidget);
    expect(find.byTooltip('Conta'), findsNothing);
  });

  testWidgets('e-mail já cadastrado mostra mensagem', (tester) async {
    final firebase = MockFirebaseAuth();
    whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
        .on(firebase)
        .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    await abrirApp(tester, firebase);

    await preencherCadastro(tester);

    expect(find.text('Já existe uma conta com este e-mail.'), findsOneWidget);
    expect(find.byTooltip('Conta'), findsNothing);
  });

  testWidgets('do cadastro dá para voltar ao login', (tester) async {
    await abrirApp(tester, MockFirebaseAuth());
    await tester.tap(find.widgetWithText(TextButton, 'Criar conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Já tenho conta · Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  Future<void> abrirRecuperacao(WidgetTester tester) async {
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
  }

  testWidgets('esqueci minha senha abre a tela de recuperação', (tester) async {
    await abrirApp(tester, MockFirebaseAuth());

    await abrirRecuperacao(tester);

    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.text('Enviar link'), findsOneWidget);
  });

  testWidgets('recuperação envia o e-mail e mostra a confirmação', (
    tester,
  ) async {
    final firebase = MockFirebaseAuth();
    whenCalling(Invocation.method(#sendPasswordResetEmail, null)).on(firebase);
    await abrirApp(tester, firebase);
    await abrirRecuperacao(tester);

    await tester.enterText(find.byType(TextFormField), 'prof@escola.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar link'));
    await tester.pumpAndSettle();

    expect(find.textContaining('prof@escola.com'), findsOneWidget);
    expect(find.text('Enviar para outro e-mail'), findsOneWidget);
  });

  testWidgets('recuperação com e-mail inválido não envia nada', (tester) async {
    await abrirApp(tester, MockFirebaseAuth());
    await abrirRecuperacao(tester);

    await tester.enterText(find.byType(TextFormField), 'isso-nao-e-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar link'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail inválido'), findsOneWidget);
    expect(find.text('Enviar para outro e-mail'), findsNothing);
  });

  testWidgets('erro ao enviar a recuperação mostra mensagem', (tester) async {
    final firebase = MockFirebaseAuth();
    whenCalling(Invocation.method(#sendPasswordResetEmail, null))
        .on(firebase)
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await abrirApp(tester, firebase);
    await abrirRecuperacao(tester);

    await tester.enterText(find.byType(TextFormField), 'prof@escola.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar link'));
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    expect(find.text('Enviar para outro e-mail'), findsNothing);
  });

  testWidgets('da recuperação dá para voltar ao login', (tester) async {
    await abrirApp(tester, MockFirebaseAuth());
    await abrirRecuperacao(tester);

    await tester.tap(find.text('Voltar para o login'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  testWidgets('no desktop, sair fica no rodapé do menu lateral', (
    tester,
  ) async {
    await abrirApp(tester, MockFirebaseAuth(signedIn: true));
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Conta'), findsNothing);
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  testWidgets('sair volta para o login', (tester) async {
    await abrirApp(tester, MockFirebaseAuth(signedIn: true));
    expect(find.byTooltip('Conta'), findsOneWidget);

    await tester.tap(find.byTooltip('Conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar com Google'), findsOneWidget);
  });
}
