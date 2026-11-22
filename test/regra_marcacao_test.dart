import 'package:flutter_dart/services/leitor_omr.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/foto_cartao.dart';

void main() {
  group('LeituraQuestao.dePreenchimento', () {
    LeituraQuestao ler(List<double> p) => LeituraQuestao.dePreenchimento(0, p);

    test('um X e o resto vazio é marcada', () {
      final q = ler([0.02, 1.0, 0.0, 0.05, 0.01]);
      expect(q.situacao, SituacaoQuestao.marcada);
      expect(q.alternativa, 1);
      expect(q.situacao.precisaRevisao, isFalse);
    });

    test('nada marcado é em branco', () {
      final q = ler([0.02, 0.05, 0.0, 0.08, 0.01]);
      expect(q.situacao, SituacaoQuestao.emBranco);
      expect(q.alternativa, isNull);
      expect(q.situacao.precisaRevisao, isTrue);
    });

    test('dois X é dupla', () {
      final q = ler([1.0, 0.02, 0.8, 0.0, 0.01]);
      expect(q.situacao, SituacaoQuestao.dupla);
      expect(q.alternativa, isNull);
    });

    test('três marcadas também é dupla', () {
      expect(ler([1.0, 1.0, 0.9, 0.0]).situacao, SituacaoQuestao.dupla);
    });

    test('X junto com um risco em outra vai para revisão', () {
      final q = ler([1.0, 0.03, 0.4, 0.02, 0.0]);
      expect(q.situacao, SituacaoQuestao.rasura);
      expect(q.alternativa, isNull);
    });

    test('só um risco ou um visto, sem X, é rasura', () {
      expect(ler([0.0, 0.4, 0.02, 0.01]).situacao, SituacaoQuestao.rasura);
    });

    test('marca bem apagada não atrapalha o X', () {
      final q = ler([0.2, 1.0, 0.0, 0.03]);
      expect(q.situacao, SituacaoQuestao.marcada);
      expect(q.alternativa, 1);
    });

    test('ruído parecido em todas as bolinhas (sombra) não é tinta', () {
      final q = ler([0.32, 0.3, 1.0, 0.31, 0.33]);
      expect(q.situacao, SituacaoQuestao.marcada);
      expect(q.alternativa, 2);
    });

    test('exatamente no limiar conta como marcada', () {
      expect(
        ler([LimitesOmr.limiarMarcada, 0, 0]).situacao,
        SituacaoQuestao.marcada,
      );
    });

    test('toda situação que pede revisão tem mensagem', () {
      for (final s in SituacaoQuestao.values) {
        expect(s.mensagem.isEmpty, !s.precisaRevisao, reason: s.name);
      }
    });
  });

  group('no gabarito fotografado', () {
    test('identifica marcada, em branco, dupla e rasura', () {
      final alternativas = List.filled(10, 5);
      final marcas = {
        (0, 1): Marca.x, // Q1 marcada B
        // Q2 em branco
        (2, 0): Marca.x, (2, 3): Marca.x, // Q3 dupla
        (3, 2): Marca.risco, // Q4 só um risco
        (4, 4): Marca.x, (4, 0): Marca.risco, // Q5 X + risco
        (5, 3): Marca.x, (5, 1): Marca.apagada, // Q6 apagada bem: vale D
        (6, 0): Marca.cheia, // Q7 pintada: vale A
        (7, 2): Marca.x, (7, 3): Marca.cheia, (7, 4): Marca.xTorto, // Q8
        (8, 1): Marca.visto, // Q9 só um visto
        (9, 2): Marca.xTorto, // Q10 X torto: vale C
      };
      for (final (sombra, ruido, cantos) in [
        (0.0, 8.0, cantosDeFrente(1500, 2000)),
        (
          0.4,
          14.0,
          const [
            Offset(200, 120),
            Offset(1380, 190),
            Offset(1450, 1930),
            Offset(90, 1850),
          ],
        ),
      ]) {
        final foto = fotografar(
          paginaGabarito(alternativas, marcas),
          largura: 1500,
          altura: 2000,
          cantos: cantos,
          sombra: sombra,
          ruido: ruido,
        );
        final leitura = LeitorOmr.ler(foto, alternativas);
        expect(
          [for (final q in leitura.leituras) q.situacao],
          [
            SituacaoQuestao.marcada,
            SituacaoQuestao.emBranco,
            SituacaoQuestao.dupla,
            SituacaoQuestao.rasura,
            SituacaoQuestao.rasura,
            SituacaoQuestao.marcada,
            SituacaoQuestao.marcada,
            SituacaoQuestao.dupla,
            SituacaoQuestao.rasura,
            SituacaoQuestao.marcada,
          ],
          reason: 'sombra $sombra',
        );
        expect(leitura.marcadas, [
          1,
          null,
          null,
          null,
          null,
          3,
          0,
          null,
          null,
          2,
        ]);
        expect(leitura.paraRevisar, [1, 2, 3, 4, 7, 8]);
      }
    });
  });
}
