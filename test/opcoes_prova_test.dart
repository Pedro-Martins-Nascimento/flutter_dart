import 'package:flutter/material.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/screens/provas/criar_prova_screen.dart';
import 'package:flutter_dart/screens/provas/gerar_provas_screen.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  final turma = Turma(
    id: 't1',
    nome: '3º ano A',
    alunos: [
      AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1'),
      AlunoTurma(id: 'a2', nome: 'Bruno', matricula: '2'),
    ],
  );
  final questoes = [
    for (var i = 1; i <= 6; i++)
      Questao(
        id: 'q$i',
        materiaId: 'd1',
        enunciado: 'Questão $i',
        alternativas: ['A$i', 'B$i', 'C$i', 'D$i', 'E$i'],
        respostaCorreta: 2,
      ),
  ];

  /// Gera [versoes] versões com as [opcoes], salva e devolve a prova salva.
  Future<ProvaRepositoryMemoria> gerarESalvar(
    WidgetTester tester,
    OpcoesProva opcoes, {
    int versoes = 4,
  }) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = ProvaRepositoryMemoria();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => GerarProvasScreen(
            repository: repo,
            dados: DadosProva(
              nomeProva: 'P1',
              disciplina: Disciplina(id: 'd1', nome: 'Mat', turmas: [turma]),
              turma: turma,
              questoes: questoes,
              opcoes: opcoes,
              versoes: versoes,
            ),
          ),
        ),
        GoRoute(
          path: '/provas-geradas',
          builder: (_, _) => const Text('lista de provas'),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TurmasRepository(iniciais: const []),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                QuestoesRepository(materias: const [], questoes: questoes),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar prova'));
    await tester.pumpAndSettle();
    return repo;
  }

  Future<List<List<String>>> ordens(
    ProvaRepositoryMemoria repo,
    String Function(QuestaoNaVersao q) campo,
  ) async {
    final prova = await repo.buscar((await repo.listar()).single.id);
    return [
      for (final v in prova!.versoes) [for (final q in v.questoes) campo(q)],
    ];
  }

  testWidgets('sem embaralhar: questões e alternativas na ordem original', (
    tester,
  ) async {
    final repo = await gerarESalvar(
      tester,
      const OpcoesProva(
        embaralharAlternativas: false,
        embaralharQuestoes: false,
      ),
    );

    for (final ordem in await ordens(repo, (q) => q.questao.id)) {
      expect(ordem, ['q1', 'q2', 'q3', 'q4', 'q5', 'q6']);
    }
    for (final ordem in await ordens(repo, (q) => q.alternativas.first)) {
      expect(ordem, ['A1', 'A2', 'A3', 'A4', 'A5', 'A6']);
    }
    // A correta continua sendo a C.
    for (final ordem in await ordens(repo, (q) => '${q.respostaCorreta}')) {
      expect(ordem.toSet(), {'2'});
    }
  });

  testWidgets('embaralhar só as questões mantém as alternativas', (
    tester,
  ) async {
    final repo = await gerarESalvar(
      tester,
      const OpcoesProva(
        embaralharAlternativas: false,
        embaralharQuestoes: true,
      ),
      versoes: 8,
    );

    final porQuestao = await ordens(repo, (q) => q.questao.id);
    // Com 8 versões de 6 questões, alguma sai fora da ordem original.
    expect(porQuestao.any((o) => o.join() != 'q1q2q3q4q5q6'), isTrue);
    for (final ordem in await ordens(
      repo,
      (q) => q.alternativas.join() == q.questao.alternativas.join()
          ? 'igual'
          : 'mudou',
    )) {
      expect(ordem.toSet(), {'igual'});
    }
  });

  testWidgets('vincular a aluno: as versões já saem com aluno', (tester) async {
    final repo = await gerarESalvar(
      tester,
      const OpcoesProva(vincularAlunos: true),
      versoes: 2,
    );

    final prova = await repo.buscar((await repo.listar()).single.id);
    expect(prova!.versoes.map((v) => v.alunoId), ['a1', 'a2']);
  });
}
