// Smoke test básico do app.
//
// ALTERADO (revisão): o teste antigo era o padrão do `flutter create`,
// testando o contador (+/0/1) da MyHomePage — removido porque
// não era mais usada (o app usa MaterialApp.router + go_router).
//
// ATUALIZADO: com o Login mergeado (initialLocation agora é '/login' em
// app_router.dart), o smoke test passou a verificar a tela de Login em
// vez da tela de Criar Prova.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/main.dart';

void main() {
  testWidgets('App inicia na tela de Login', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifica que a tela inicial (rota '/login') carregou.
    // "Entrar" aparece duas vezes (título da tela + texto do botão).
    expect(find.text('Entrar'), findsNWidgets(2));
    expect(find.text('Correção de provas'), findsOneWidget);
  });
}
