import 'questao.dart';

// Questão já embaralhada dentro de uma versão específica: alternativas na
// ordem impressa e `respostaCorreta` recalculado pra essa ordem — é o
// gabarito daquela versão.
class QuestaoNaVersao {
  final Questao questao;
  final List<String> alternativas;
  final int respostaCorreta;

  QuestaoNaVersao({
    required this.questao,
    required this.alternativas,
    required this.respostaCorreta,
  });
}

class VersaoProva {
  final String id;
  final String qrCode;
  String? alunoId; // RF11 — vínculo é opcional
  final List<QuestaoNaVersao> questoes;

  // Campos usados no cabeçalho de identificação do PDF
  final String materia;
  final String professor;
  final String? turma;
  final String provaNome;

  VersaoProva({
    required this.id,
    required this.qrCode,
    required this.questoes,
    this.alunoId,
    this.materia = 'Matemática',
    this.professor = 'Prof. responsável',
    this.turma,
    this.provaNome = 'Prova sem título',
  });
}
