import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dart/models/correcao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/screens/provas/listar_provas_screen.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/provas_repository.dart';
import 'package:flutter_dart/services/relatorio_excel.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'correcao_fixtures.dart';

void main() {
  final turmaA = Turma(
    id: 't1',
    nome: 'Turma A',
    alunos: [
      AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1'),
      AlunoTurma(id: 'b1', nome: 'Bruno', matricula: '2'),
    ],
  );

  Future<ProvaRepositoryMemoria> repoComProva(String? turma) async {
    final repo = ProvaRepositoryMemoria();
    await repo.criar(
      ProvaGerada(
        id: 'p1',
        nome: 'Prova de Matemática',
        materia: 'Matemática',
        turma: turma,
        criadoEm: DateTime(2026, 5, 10),
        versoes: const [],
      ),
    );
    return repo;
  }

  Future<void> abrir(
    WidgetTester tester,
    ProvaRepositoryMemoria repo, {
    required Future<List<Correcao>> Function() correcoes,
    required Future<bool> Function(String, Uint8List) salvar,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TurmasRepository(iniciais: [turmaA]),
        child: MaterialApp(
          home: ListarProvasScreen(
            repository: repo,
            carregarCorrecoes: correcoes,
            salvarArquivo: salvar,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tocarExportar(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Opções da prova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportar notas (.xlsx)'));
    await tester.pumpAndSettle();
  }

  List<List<Object?>> lerLinhas(Uint8List bytes) {
    final aba = Excel.decodeBytes(bytes)[nomeAbaNotas];
    return [
      for (final linha in aba.rows)
        [
          for (final c in linha)
            c?.value is TextCellValue
                ? (c!.value as TextCellValue).value.toString()
                : c?.value is DoubleCellValue
                ? (c!.value as DoubleCellValue).value
                : c?.value is IntCellValue
                ? (c!.value as IntCellValue).value.toDouble()
                : null,
        ],
    ];
  }

  testWidgets('exporta a turma toda: nota de quem foi corrigido e vazio para '
      'quem não foi', (tester) async {
    String? nomeSalvo;
    Uint8List? bytesSalvos;
    await abrir(
      tester,
      await repoComProva('Turma A'),
      correcoes: () async => [
        correcao('c1', provaId: 'p1', alunoId: 'a1', alunoNome: 'Ana'),
      ],
      salvar: (nome, bytes) async {
        nomeSalvo = nome;
        bytesSalvos = bytes;
        return true;
      },
    );

    await tocarExportar(tester);

    expect(nomeSalvo, 'notas_Prova_de_Matemática.xlsx');
    expect(lerLinhas(bytesSalvos!), [
      ['Aluno', 'Prova', 'Nota'],
      ['Ana', 'Prova de Matemática', 5.0],
      ['Bruno', 'Prova de Matemática', null],
    ]);
    expect(find.text('Planilha de notas salva.'), findsOneWidget);
  });

  testWidgets('prova sem alunos nem correções avisa e não salva', (
    tester,
  ) async {
    var salvou = false;
    await abrir(
      tester,
      await repoComProva(null),
      correcoes: () async => [],
      salvar: (nome, bytes) async => salvou = true,
    );

    await tocarExportar(tester);

    expect(salvou, isFalse);
    expect(
      find.textContaining('ainda não tem alunos nem correções'),
      findsOneWidget,
    );
  });

  testWidgets('erro ao carregar as correções mostra o aviso', (tester) async {
    await abrir(
      tester,
      await repoComProva('Turma A'),
      correcoes: () async => throw StateError('sem conexão'),
      salvar: (nome, bytes) async => true,
    );

    await tocarExportar(tester);

    expect(find.text('Não foi possível exportar as notas.'), findsOneWidget);
  });

  testWidgets('cancelar o salvamento não mostra mensagem de sucesso', (
    tester,
  ) async {
    await abrir(
      tester,
      await repoComProva('Turma A'),
      correcoes: () async => [],
      salvar: (nome, bytes) async => false,
    );

    await tocarExportar(tester);

    expect(find.text('Planilha de notas salva.'), findsNothing);
  });
}
