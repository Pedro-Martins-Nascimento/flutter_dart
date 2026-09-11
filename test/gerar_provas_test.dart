// Testes do embaralhamento de versão de prova (RF09/RF10).
//
// A regra que importa aqui: depois de embaralhar as alternativas de uma
// questão, `alternativas[respostaCorreta]` da versão embaralhada tem que
// continuar sendo o MESMO texto que era a alternativa certa na questão
// original — senão o gabarito da versão fica errado e ninguém percebe
// olhando a prova impressa.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/screens/provas/gerar_provas_screen.dart';

void main() {
  final banco = [
    Questao(
      id: 'q1',
      materiaId: 'mat1',
      enunciado: 'Quanto é 7 x 8?',
      alternativas: ['54', '56', '58', '64'],
      respostaCorreta: 1,
    ),
    Questao(
      id: 'q2',
      materiaId: 'mat1',
      enunciado: 'Qual a raiz quadrada de 144?',
      alternativas: ['11', '12', '13', '14'],
      respostaCorreta: 1,
    ),
    Questao(
      id: 'q3',
      materiaId: 'mat1',
      enunciado: 'Capital da Austrália?',
      alternativas: ['Sydney', 'Melbourne', 'Camberra', 'Perth', 'Darwin'],
      respostaCorreta: 2,
    ),
  ];

  test('respostaCorreta sempre aponta pro texto certo, mesmo embaralhado', () {
    final random = Random(42);

    // Roda várias vezes com sementes diferentes pra não depender de uma
    // única ordem de sorteio ter dado certo por acaso.
    for (var tentativa = 0; tentativa < 200; tentativa++) {
      final versao = materializarQuestoes(banco, ModoProva.mesmaEmbaralhada, random);

      for (final questaoNaVersao in versao) {
        final textoNaPosicaoCorreta =
            questaoNaVersao.alternativas[questaoNaVersao.respostaCorreta];
        final textoOriginalCorreto = questaoNaVersao
            .questao
            .alternativas[questaoNaVersao.questao.respostaCorreta];

        expect(textoNaPosicaoCorreta, textoOriginalCorreto);
      }
    }
  });

  test('mesmaEmbaralhada leva todas as questões do banco', () {
    final random = Random(1);
    final versao = materializarQuestoes(banco, ModoProva.mesmaEmbaralhada, random);
    expect(versao.length, banco.length);
  });

  test('conjuntosDiferentes pode levar menos questões que o banco', () {
    final bancoGrande = List.generate(
      10,
      (i) => Questao(
        id: 'g$i',
        materiaId: 'mat1',
        enunciado: 'Questão $i',
        alternativas: ['a', 'b', 'c', 'd'],
        respostaCorreta: 0,
      ),
    );
    final random = Random(7);
    final versao = materializarQuestoes(bancoGrande, ModoProva.conjuntosDiferentes, random);
    expect(versao.length, lessThan(bancoGrande.length));
    expect(versao.length, greaterThan(0));
  });
}
