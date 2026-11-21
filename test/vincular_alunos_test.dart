import 'package:flutter/material.dart';
import 'package:flutter_dart/models/prova_gerada.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/screens/provas/criar_prova_screen.dart';
import 'package:flutter_dart/screens/provas/gerar_provas_screen.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  final turma = Turma(
    id: 't1',
    nome: '3º ano A',
    alunos: [
      AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1'),
      AlunoTurma(id: 'a2', nome: 'Bruno', matricula: '2'),
      AlunoTurma(id: 'a3', nome: 'Caio', matricula: '3'),
    ],
  );
  final questao = Questao(
    id: 'q1',
    materiaId: 'm1',
    enunciado: 'Quanto é 2 + 2?',
    alternativas: ['3', '4', '5', '6'],
    respostaCorreta: 1,
  );

  /// Tela de gerar provas com [versoes] versões para a turma de 3 alunos.
  Future<void> abrir(WidgetTester tester, {required int versoes}) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TurmasRepository(iniciais: const []),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                QuestoesRepository(materias: const [], questoes: [questao]),
          ),
        ],
        child: MaterialApp(
          home: GerarProvasScreen(
            repository: ProvaRepositoryMemoria(),
            dados: DadosProva(
              nomeProva: 'P1',
              disciplina: Disciplina(id: 'd1', nome: 'Mat', turmas: [turma]),
              turma: turma,
              questoes: [questao],
              modo: ModoProva.mesmaEmbaralhada,
              versoes: versoes,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder campos() => find.byType(DropdownButtonFormField<String?>);

  testWidgets('começa sem vínculo: caixa desmarcada e sem campo de aluno', (
    tester,
  ) async {
    await abrir(tester, versoes: 2);

    expect(find.text('Vincular cada prova a um aluno'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    expect(campos(), findsNothing);
    expect(find.textContaining('sem prova'), findsNothing);
  });

  testWidgets('marcar já escolhe um aluno diferente para cada prova', (
    tester,
  ) async {
    await abrir(tester, versoes: 3);

    await tester.tap(find.text('Vincular cada prova a um aluno'));
    await tester.pumpAndSettle();

    expect(campos(), findsNWidgets(3));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Caio'), findsOneWidget);
    // Todos têm prova: nenhum aviso.
    expect(find.textContaining('sem prova'), findsNothing);
  });

  testWidgets('com menos provas que alunos, avisa quem ficou sem prova', (
    tester,
  ) async {
    await abrir(tester, versoes: 2);

    await tester.tap(find.text('Vincular cada prova a um aluno'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 aluno ficou sem prova'), findsOneWidget);
    expect(find.textContaining('Caio.'), findsOneWidget);

    // Desmarcar tira os vínculos e o aviso.
    await tester.tap(find.text('Vincular cada prova a um aluno'));
    await tester.pumpAndSettle();
    expect(campos(), findsNothing);
    expect(find.textContaining('sem prova'), findsNothing);
  });

  testWidgets('aluno que já está em outra prova não pode ser escolhido', (
    tester,
  ) async {
    await abrir(tester, versoes: 2);
    await tester.tap(find.text('Vincular cada prova a um aluno'));
    await tester.pumpAndSettle();

    // Prova A ficou com a Ana e a Prova B com o Bruno. Abre a lista da A.
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();

    final bruno = find.text('Bruno · já na Prova B');
    expect(bruno, findsOneWidget);
    final item = tester.widget<DropdownMenuItem<String?>>(
      find.ancestor(
        of: bruno,
        matching: find.byType(DropdownMenuItem<String?>),
      ),
    );
    expect(item.enabled, isFalse);

    // Tocar no Bruno não muda nada: ele continua só na Prova B.
    await tester.tap(bruno, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('mais de uma prova'), findsNothing);
  });

  testWidgets('prova salva com aluno repetido mostra aviso', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    VersaoProva versao(String id) => VersaoProva(
      id: id,
      qrCode: 'qr-$id',
      questoes: const [],
      alunoId: 'a1',
      disciplina: 'Mat',
      turma: '3º ano A',
    );
    final prova = ProvaGerada(
      id: 'p1',
      nome: 'P1',
      materia: 'Mat',
      turma: '3º ano A',
      disciplina: 'Mat',
      criadoEm: DateTime(2026, 11, 19),
      versoes: [versao('v1'), versao('v2')],
    );
    final repo = ProvaRepositoryMemoria();
    await repo.criar(prova);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TurmasRepository(
              iniciais: [
                Disciplina(id: 'd1', nome: 'Mat', turmas: [turma]),
              ],
            ),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                QuestoesRepository(materias: const [], questoes: [questao]),
          ),
        ],
        child: MaterialApp(
          home: GerarProvasScreen(repository: repo, provaExistente: prova),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('1 aluno está em mais de uma prova'),
      findsOneWidget,
    );
    expect(find.textContaining('Ana.'), findsOneWidget);
  });
}
