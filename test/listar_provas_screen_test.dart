import 'package:flutter/material.dart';
import 'package:flutter_dart/screens/provas/listar_provas_screen.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/provas_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(WidgetTester tester, ProvaRepositoryMemoria repo) =>
      tester.pumpWidget(
        MaterialApp(
          home: ListarProvasScreen(
            repository: repo,
            carregarCorrecoes: () async => [],
          ),
        ),
      );

  testWidgets('repository vazio mostra o aviso de vazio', (tester) async {
    await abrir(tester, ProvaRepositoryMemoria());
    await tester.pump();
    expect(find.text('Nenhuma prova gerada ainda'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mostra as provas do repository e acompanha mudanças', (
    tester,
  ) async {
    final repo = ProvaRepositoryMemoria.comMocks();
    await abrir(tester, repo);
    await tester.pump();
    expect(find.text('P1 — Matemática'), findsOneWidget);
    expect(find.textContaining('4 versão(ões)'), findsOneWidget);

    await repo.criar(
      ProvaGerada(
        id: 'nova',
        nome: 'Prova nova',
        materia: 'Física',
        turma: null,
        criadoEm: DateTime.now(),
        versoes: const [],
      ),
    );
    await tester.pump();
    expect(find.text('Prova nova'), findsOneWidget);

    await repo.excluir('nova');
    await tester.pump();
    expect(find.text('Prova nova'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
