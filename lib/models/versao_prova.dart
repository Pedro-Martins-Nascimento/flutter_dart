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
  final String? disciplina;
  final String provaNome;

  VersaoProva({
    required this.id,
    required this.qrCode,
    required this.questoes,
    this.alunoId,
    this.materia = 'Matemática',
    this.professor = professorPadrao,
    this.turma,
    this.disciplina,
    this.provaNome = 'Prova sem título',
  });

  /// Texto usado quando não se sabe o nome do professor (provas antigas
  /// guardavam só isso).
  static const professorPadrao = 'Prof. responsável';

  /// Letra que identifica a versão no caderno e no gabarito ("Prova B" /
  /// "Gabarito da Prova B"): v1 → A, v2 → B, …, v26 → Z, v27 → AA.
  String get letra => letraDe(id);

  /// Letra da versão de id [id]. Um id fora do padrão `v<número>` aparece
  /// como está, em maiúsculas.
  static String letraDe(String id) {
    final numero = id.startsWith('v') ? int.tryParse(id.substring(1)) : null;
    if (numero == null || numero < 1) return id.toUpperCase();
    var resto = numero;
    var letras = '';
    while (resto > 0) {
      resto--;
      letras = String.fromCharCode(65 + resto % 26) + letras;
      resto ~/= 26;
    }
    return letras;
  }

  /// Cópia com [nome] no campo professor, mas só se esta versão ainda tiver
  /// o texto padrão: um nome já gravado na prova não é trocado.
  VersaoProva comProfessorSePadrao(String nome) {
    if (professor != professorPadrao) return this;
    return VersaoProva(
      id: id,
      qrCode: qrCode,
      questoes: questoes,
      alunoId: alunoId,
      materia: materia,
      professor: nome,
      turma: turma,
      disciplina: disciplina,
      provaNome: provaNome,
    );
  }
}
