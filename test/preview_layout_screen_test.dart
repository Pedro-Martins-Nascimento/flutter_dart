import 'package:flutter/material.dart';
import 'package:flutter_dart/screens/provas/preview_layout_screen.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abrindo só com o id, mostra o carregando e depois avisa que a '
      'prova não existe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PreviewLayoutScreen.deProva(
          repository: ProvaRepositoryMemoria(),
          provaId: 'nao_existe',
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    expect(find.text('Prova não encontrada.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
