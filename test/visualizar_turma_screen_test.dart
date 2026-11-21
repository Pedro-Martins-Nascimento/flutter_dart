import 'package:flutter/material.dart';
import 'package:flutter_dart/models/prova_gerada.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/screens/turmas/visualizar_turma_screen.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'correcao_fixtures.dart';
import 'prova_repository_contrato.dart';

/// Cópia de [base] gravada na [disciplina] / [turma] indicadas.
ProvaGerada _naTurma(
  ProvaGerada base, {
  required String nome,
  String? disciplina,
  required String turma,
}) => ProvaGerada(
  id: base.id,
  nome: nome,
  materia: base.materia,
  turma: turma,
  disciplina: disciplina,
  criadoEm: base.criadoEm,
  versoes: base.versoes,
);

void main() {
  // Disciplina "Matemática" com as turmas "Manhã" (Bia e Caio) e "Tarde".
  // A prova p1 é da Manhã, com 3 versões: a v1 é da Bia e já foi corrigida,
  // a v2 foi corrigida sem aluno e a v3 está pendente. A prova "Da tarde" é
  // da outra turma, e "Antiga" foi gravada antes das turmas (só com o nome
  // da disciplina): ela aparece na primeira turma.
  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provas = ProvaRepositoryMemoria();
    final p1 = prova('p1', versoes: 3)..versoes.first.alunoId = 'a1';
    await provas.criar(
      _naTurma(p1, nome: 'Prova p1', disciplina: 'Matemática', turma: 'Manhã'),
    );
    await provas.criar(
      _naTurma(
        prova('p2'),
        nome: 'Da tarde',
        disciplina: 'Matemática',
        turma: 'Tarde',
      ),
    );
    await provas.criar(
      _naTurma(prova('p3'), nome: 'Antiga', turma: 'Matemática'),
    );

    final correcoes = CorrecaoRepositoryMemoria();
    await correcoes.salvar(
      correcao('c1', provaId: 'p1', versaoId: 'v1', alunoId: 'a1'),
    );
    await correcoes.salvar(correcao('c2', provaId: 'p1', versaoId: 'v2'));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TurmasRepository(
          iniciais: [
            Disciplina(
              id: 'd1',
              nome: 'Matemática',
              turmas: [
                Turma(
                  id: 't1',
                  nome: 'Manhã',
                  alunos: [
                    AlunoTurma(id: 'a1', nome: 'Bia', matricula: '001'),
                    AlunoTurma(id: 'a2', nome: 'Caio', matricula: '002'),
                  ],
                ),
                Turma(id: 't2', nome: 'Tarde'),
              ],
            ),
          ],
        ),
        child: MaterialApp(
          home: VisualizarTurmaScreen(
            disciplinaId: 'd1',
            turmaId: 't1',
            provas: provas,
            correcoes: correcoes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('abas de alunos e de provas, com as contagens da turma', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Manhã'), findsOneWidget);
    expect(find.text('Alunos (2)'), findsOneWidget);
    // A prova da Manhã e a antiga; a da Tarde fica de fora.
    expect(find.text('Provas (2)'), findsOneWidget);
    // A Bia tem a correção vinculada; o Caio não.
    expect(find.text('1 correção'), findsOneWidget);
  });

  testWidgets('aluno sem correção vinculada mostra um aviso', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Caio'));
    await tester.pump();

    expect(
      find.text('Caio ainda não tem prova corrigida vinculada.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a prova abre todas as folhas: com aluno, sem aluno e pendentes',
    (tester) async {
      await abrir(tester);

      await tester.tap(find.text('Provas (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Prova p1'), findsOneWidget);
      expect(find.text('Antiga'), findsOneWidget);
      expect(find.text('Da tarde'), findsNothing);
      expect(find.textContaining('2 de 3 corrigidas'), findsOneWidget);

      await tester.tap(find.text('Prova p1'));
      await tester.pumpAndSettle();

      // v1: Bia, corrigida. v2: sem aluno, corrigida. v3: sem aluno, pendente.
      expect(find.text('Bia'), findsOneWidget);
      expect(find.text('Sem aluno vinculado'), findsNWidgets(2));
      expect(find.text('Prova A'), findsOneWidget);
      expect(find.text('Prova C'), findsOneWidget);
      expect(find.text('5,0'), findsNWidgets(2));
      expect(find.text('Pendente'), findsOneWidget);
    },
  );
}
