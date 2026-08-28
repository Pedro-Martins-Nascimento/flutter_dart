// Smoke test básico do app.
//
// ALTERADO (revisão): o teste antigo era o padrão do `flutter create`,
// testando o contador (+/0/1) da MyHomePage — removido porque
// não era mais usada (o app usa MaterialApp.router + go_router). Como a
// tela inicial agora é a CriarProvaScreen (initialLocation em
// app_router.dart), o smoke test aqui só confirma que o app sobe sem
// erro e que a tela de Criar Prova aparece.
//
// TODO: Este teste é provisório. Quando o Login for implementado e passar
// a ser a tela inicial, atualizar o teste para verificar a tela de Login.
// Conforme as outras telas forem implementadas, criar testes específicos
// para cada uma delas.


import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/main.dart';

void main() {
  testWidgets('App inicia na tela de Criar Prova', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifica que a tela inicial (rota '/criar-prova') carregou.
    expect(find.text('Criar Prova'), findsOneWidget);
    expect(find.text('1. SELECIONE A(S) MATÉRIA(S)'), findsOneWidget);
  });
}