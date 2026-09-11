// Testes do cálculo de nota e das agregações usadas nas telas de
// Início/Corrigir/Estatística (RF16/RF17/RF18).

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/screens/provas/gerar_provas_screen.dart';
import 'package:flutter_dart/services/correcoes_repository.dart';

VersaoProva _versaoDeTeste(String id, List<Questao> questoes) {
  return VersaoProva(
    id: id,
    qrCode: 'QR-$id',
    questoes: [
      for (final q in questoes)
        QuestaoNaVersao(questao: q, alternativas: q.alternativas, respostaCorreta: q.respostaCorreta),
    ],
    provaNome: 'Prova teste',
    materia: 'Matemática',
  );
}

void main() {
  final q1 = Questao(id: 'q1', materiaId: 'mat1', enunciado: '7x8', alternativas: ['54', '56'], respostaCorreta: 1);
  final q2 = Questao(id: 'q2', materiaId: 'mat1', enunciado: '9x9', alternativas: ['81', '72'], respostaCorreta: 0);
  final q3 = Questao(id: 'q3', materiaId: 'mat2', enunciado: 'Capital X', alternativas: ['A', 'B'], respostaCorreta: 0);

  // CorrecoesRepository é um singleton global — sem limpar entre testes,
  // uma correção salva num teste vaza pro cálculo de agregação do
  // próximo.
  setUp(() => CorrecoesRepository.instance.limparParaTeste());

  test('nota e acertos batem com as respostas certas/erradas', () {
    final versao = _versaoDeTeste('v1', [q1, q2, q3]);
    final correcao = Correcao(
      id: 'c1',
      versao: versao,
      provaNome: 'Prova teste',
      materia: 'Matemática',
      turma: null,
      alunoNome: 'Fulano',
      corrigidoEm: DateTime(2026),
      respostas: [
        RespostaQuestao(alternativaMarcada: 1, correta: true), // q1 certa
        RespostaQuestao(alternativaMarcada: 1, correta: false), // q2 errada
        RespostaQuestao(alternativaMarcada: 0, correta: true), // q3 certa
      ],
    );

    expect(correcao.acertos, 2);
    expect(correcao.total, 3);
    expect(correcao.nota, closeTo(6.67, 0.01));
  });

  test('nota é 0 quando não há respostas', () {
    final versao = _versaoDeTeste('v2', []);
    final correcao = Correcao(
      id: 'c2',
      versao: versao,
      provaNome: 'Prova teste',
      materia: 'Matemática',
      turma: null,
      alunoNome: null,
      corrigidoEm: DateTime(2026),
      respostas: [],
    );

    expect(correcao.nota, 0);
  });

  test('percentualAcertoPorMateria agrega certo entre correções', () {
    final repo = CorrecoesRepository.instance;

    // mat1: 1 acerto em 2 questões (50%). mat2: 1 acerto em 1 (100%).
    repo.salvar(Correcao(
      id: 'agg1',
      versao: _versaoDeTeste('vagg1', [q1, q2, q3]),
      provaNome: 'Prova agregação',
      materia: 'Matemática',
      turma: null,
      alunoNome: null,
      corrigidoEm: DateTime(2026),
      respostas: [
        RespostaQuestao(alternativaMarcada: 1, correta: true),
        RespostaQuestao(alternativaMarcada: 1, correta: false),
        RespostaQuestao(alternativaMarcada: 0, correta: true),
      ],
    ));

    final porMateria = repo.percentualAcertoPorMateria();
    expect(porMateria['mat1'], 50.0);
    expect(porMateria['mat2'], 100.0);
  });

  test('jaCorrigida reflete o que foi salvo', () {
    final repo = CorrecoesRepository.instance;
    expect(repo.jaCorrigida('vnaoexiste'), isFalse);

    repo.salvar(Correcao(
      id: 'jc1',
      versao: _versaoDeTeste('vjc1', [q1]),
      provaNome: 'Prova jc',
      materia: 'Matemática',
      turma: null,
      alunoNome: null,
      corrigidoEm: DateTime(2026),
      respostas: [RespostaQuestao(alternativaMarcada: 1, correta: true)],
    ));

    expect(repo.jaCorrigida('vjc1'), isTrue);
  });
}
