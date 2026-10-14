import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/main.dart';
import 'package:flutter_dart/services/auth_service.dart';

void main() {
  testWidgets('App inicia na tela de Login', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(auth: AuthService(auth: MockFirebaseAuth())));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsNWidgets(2));
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Correção de provas'), findsOneWidget);
  });
}
