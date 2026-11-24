import 'package:flutter/material.dart';
import 'package:flutter_dart/models/correcao.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/screens/inicio/estatistica_completa_screen.dart';
import 'package:flutter_dart/services/correcao_mapper.dart';
import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_dart/services/estatistica_service.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'correcao_fixtures.dart';
import 'helpers/provas_exemplo.dart';

/// Resposta de uma versão cujas alternativas foram impressas na ordem
/// [ordem] (posição impressa -> índice no banco). [marcadaNoBanco] e
/// [corretaNoBanco] são índices do banco.
RespostaQuestao respostaEmbaralhada(
  String questaoId, {
  required List<int> ordem,
  required int marcadaNoBanco,
  int corretaNoBanco = 0,
  List<String>? textos,
}) => RespostaQuestao(
  questaoId: questaoId,
  materiaId: 'mat1',
  enunciado: 'Enunciado de $questaoId',
  alternativaMarcada: ordem.indexOf(marcadaNoBanco),
  respostaCorreta: ordem.indexOf(corretaNoBanco),
  ordemNoBanco: ordem,
  alternativasNoBanco: textos,
);

void main() {
  final questaoBanco = Questao(
    id: 'q1',
    materiaId: 'mat1',
    enunciado: 'Quanto é 2 + 2?',
    alternativas: const ['4', '3', '5', '22'],
    respostaCorreta: 0,
  );

  group('QuestaoNaVersao.ordemNoBanco', () {
    test('mapeia cada alternativa impressa ao índice do banco', () {
      final versao = QuestaoNaVersao(
        questao: questaoBanco,
        alternativas: const ['22', '4', '5', '3'],
        respostaCorreta: 1,
      );
      expect(versao.ordemNoBanco, [3, 0, 2, 1]);
    });

    test('textos repetidos pegam índices diferentes', () {
      final repetida = Questao(
        id: 'q2',
        materiaId: 'mat1',
        enunciado: 'Repetida',
        alternativas: const ['x', 'x', 'y'],
        respostaCorreta: 2,
      );
      final versao = QuestaoNaVersao(
        questao: repetida,
        alternativas: const ['x', 'y', 'x'],
        respostaCorreta: 1,
      );
      expect(versao.ordemNoBanco, [0, 2, 1]);
    });
  });

  group('RespostaQuestao no banco', () {
    test('converte marcada e certa para a ordem do banco', () {
      final r = respostaEmbaralhada(
        'q1',
        ordem: const [3, 0, 2, 1],
        marcadaNoBanco: 2,
      );
      expect(r.marcadaNoBanco, 2);
      expect(r.corretaNoBanco, 0);
    });

    test('sem ordem (correção antiga) fica nulo', () {
      final r = resposta('q1', certa: true);
      expect(r.marcadaNoBanco, isNull);
      expect(r.corretaNoBanco, isNull);
    });

    test('o mapper guarda e lê a ordem; documento antigo segue sem ela', () {
      final original = correcao(
        'c1',
        respostas: [
          respostaEmbaralhada(
            'q1',
            ordem: const [1, 0],
            marcadaNoBanco: 1,
            textos: const ['sim', 'não'],
          ),
        ],
      );
      final mapa = CorrecaoMapper.paraMapa(original);
      final lida = CorrecaoMapper.deMapa('c1', mapa);
      expect(lida.respostas.single.ordemNoBanco, [1, 0]);
      expect(lida.respostas.single.alternativasNoBanco, ['sim', 'não']);

      final antiga = CorrecaoMapper.deMapa(
        'c2',
        CorrecaoMapper.paraMapa(correcao('c2')),
      );
      expect(antiga.respostas.first.ordemNoBanco, isNull);
      expect(antiga.respostas.first.alternativasNoBanco, isNull);
      expect(
        (CorrecaoMapper.paraMapa(correcao('c2'))['respostas'] as List).first,
        isNot(contains('ordemNoBanco')),
      );
    });
  });

  group('distribuicaoAlternativas', () {
    test('junta versões embaralhadas pela ordem do banco', () {
      // Duas versões com a mesma questão em ordens diferentes. Três alunos
      // marcaram a alternativa C do banco (errada) e um marcou a A (certa).
      final c = [
        correcao(
          'a',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [0, 1, 2, 3],
              marcadaNoBanco: 2,
            ),
          ],
        ),
        correcao(
          'b',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [3, 2, 1, 0],
              marcadaNoBanco: 2,
            ),
          ],
        ),
        correcao(
          'c',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [2, 0, 3, 1],
              marcadaNoBanco: 2,
            ),
          ],
        ),
        correcao(
          'd',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [3, 2, 1, 0],
              marcadaNoBanco: 0,
            ),
          ],
        ),
      ];

      final d = EstatisticaService.distribuicaoAlternativas(c).single;
      expect(d.questaoId, 'q1');
      expect(d.contagem, [1, 0, 3, 0]);
      expect(d.correta, 0);
      expect(d.maisMarcadas, [2]);
      expect(d.respostas, 4);
    });

    test('empate devolve todas as mais marcadas', () {
      final c = [
        correcao(
          'a',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [0, 1, 2],
              marcadaNoBanco: 1,
            ),
          ],
        ),
        correcao(
          'b',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [0, 1, 2],
              marcadaNoBanco: 2,
            ),
          ],
        ),
      ];
      expect(
        EstatisticaService.distribuicaoAlternativas(c).single.maisMarcadas,
        [1, 2],
      );
    });

    test('correções sem ordem ficam de fora', () {
      final c = [
        correcao('antiga'),
        correcao(
          'nova',
          respostas: [
            respostaEmbaralhada('q1', ordem: const [1, 0], marcadaNoBanco: 1),
          ],
        ),
      ];
      final lista = EstatisticaService.distribuicaoAlternativas(c);
      expect(lista.map((d) => d.questaoId), ['q1']);
      expect(lista.single.respostas, 1);
    });

    test('ordena da questão com menor acerto para a de maior', () {
      final c = [
        correcao(
          'a',
          respostas: [
            respostaEmbaralhada('qBoa', ordem: const [0, 1], marcadaNoBanco: 0),
            respostaEmbaralhada(
              'qRuim',
              ordem: const [0, 1],
              marcadaNoBanco: 1,
            ),
          ],
        ),
      ];
      expect(
        EstatisticaService.distribuicaoAlternativas(c).map((d) => d.questaoId),
        ['qRuim', 'qBoa'],
      );
    });

    test('questão editada entre aplicações vira grupos separados', () {
      final c = [
        correcao(
          'a',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [0, 1],
              marcadaNoBanco: 1,
              textos: const ['4', '5'],
            ),
          ],
        ),
        correcao(
          'b',
          respostas: [
            respostaEmbaralhada(
              'q1',
              ordem: const [0, 1],
              marcadaNoBanco: 1,
              textos: const ['4', '6'],
            ),
          ],
        ),
      ];
      final d = EstatisticaService.distribuicaoAlternativas(c);
      expect(d, hasLength(2));
      expect(d.map((q) => q.alternativas), [
        ['4', '5'],
        ['4', '6'],
      ]);
      expect(d.every((q) => q.contagem[1] == 1), isTrue);
    });

    test('sem correções é vazia', () {
      expect(EstatisticaService.distribuicaoAlternativas([]), isEmpty);
    });
  });

  group('tela de estatística', () {
    Future<void> abrir(
      WidgetTester tester,
      CorrecaoRepositoryMemoria correcoes, {
      Questao? questaoNoBanco,
    }) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => QuestoesRepository(
                materias: materiasMock,
                questoes: [questaoNoBanco ?? questaoBanco],
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => TurmasRepository(iniciais: const []),
            ),
          ],
          child: MaterialApp(
            home: EstatisticaCompletaScreen(correcoes: correcoes),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('mostra a contagem por alternativa e a mais marcada', (
      tester,
    ) async {
      final correcoes = CorrecaoRepositoryMemoria();
      for (final (id, marcada) in [('a', 2), ('b', 2), ('c', 0)]) {
        await correcoes.salvar(
          correcao(
            id,
            respostas: [
              respostaEmbaralhada(
                'q1',
                ordem: const [3, 2, 1, 0],
                marcadaNoBanco: marcada,
                textos: questaoBanco.alternativas,
              ),
            ],
          ),
        );
      }

      await abrir(tester, correcoes);

      expect(find.text('ALTERNATIVAS MARCADAS POR QUESTÃO'), findsOneWidget);
      expect(
        find.text('3 resposta(s) · certa: A · mais marcada: C'),
        findsOneWidget,
      );
      // Texto da alternativa vem da cópia guardada na correção.
      expect(find.text('A) 4'), findsOneWidget);
      expect(find.text('C) 5'), findsOneWidget);
      Text contagem(String letra) =>
          tester.widget<Text>(find.byKey(ValueKey('contagem_q1_$letra')));
      expect(contagem('A').data, '1 · 33%');
      expect(contagem('B').data, '0 · 0%');
      expect(contagem('C').data, '2 · 67%');
      expect(contagem('D').data, '0 · 0%');
    });

    testWidgets('editar a questão depois não muda os textos do histórico', (
      tester,
    ) async {
      // Salva a correção com as alternativas da prova aplicada.
      final correcoes = CorrecaoRepositoryMemoria();
      final versao = QuestaoNaVersao(
        questao: questaoBanco,
        alternativas: const ['22', '4', '5', '3'],
        respostaCorreta: 1,
      );
      await correcoes.salvar(
        correcao(
          'c1',
          respostas: [
            RespostaQuestao(
              questaoId: 'q1',
              materiaId: 'mat1',
              enunciado: questaoBanco.enunciado,
              alternativaMarcada: 2,
              respostaCorreta: versao.respostaCorreta,
              ordemNoBanco: versao.ordemNoBanco,
              alternativasNoBanco: questaoBanco.alternativas,
            ),
          ],
        ),
      );

      // Depois, o professor edita as alternativas da questão no banco.
      final editada = Questao(
        id: 'q1',
        materiaId: 'mat1',
        enunciado: 'Quanto é 2 + 2?',
        alternativas: const ['quatro', 'três', 'cinco', 'vinte e dois'],
        respostaCorreta: 0,
      );
      await abrir(tester, correcoes, questaoNoBanco: editada);

      expect(find.text('A) 4'), findsOneWidget);
      expect(find.text('C) 5'), findsOneWidget);
      expect(find.textContaining('quatro'), findsNothing);
      expect(find.textContaining('cinco'), findsNothing);
    });

    testWidgets('só correções antigas avisa que a distribuição vem depois', (
      tester,
    ) async {
      final correcoes = CorrecaoRepositoryMemoria();
      await correcoes.salvar(correcao('c1'));

      await abrir(tester, correcoes);

      expect(
        find.textContaining('ainda não guardam a ordem das alternativas'),
        findsOneWidget,
      );
    });
  });
}
