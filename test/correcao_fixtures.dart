import 'package:flutter_dart/models/correcao.dart';

/// Resposta de uma questão; [certa] decide se o aluno acertou.
RespostaQuestao resposta(
  String questaoId, {
  required bool certa,
  String materiaId = 'mat1',
}) => RespostaQuestao(
  questaoId: questaoId,
  materiaId: materiaId,
  enunciado: 'Enunciado de $questaoId',
  alternativaMarcada: certa ? 1 : 0,
  respostaCorreta: 1,
);

Correcao correcao(
  String id, {
  String provaId = 'p1',
  String versaoId = 'v1',
  String? alunoId,
  String? alunoNome,
  int diasAtras = 0,
  List<RespostaQuestao>? respostas,
}) => Correcao(
  id: id,
  provaId: provaId,
  versaoId: versaoId,
  provaNome: 'Prova $provaId',
  materia: 'Matemática',
  turma: 'Turma A',
  alunoId: alunoId,
  alunoNome: alunoNome,
  corrigidoEm: DateTime(2026, 5, 10).subtract(Duration(days: diasAtras)),
  respostas:
      respostas ?? [resposta('q1', certa: true), resposta('q2', certa: false)],
);
