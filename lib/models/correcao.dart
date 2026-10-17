/// Resposta de uma questão numa folha corrigida.
///
/// Guarda o que a estatística precisa (matéria e enunciado) para que ela seja
/// calculada só com as correções, sem reler as versões das provas. Como na
/// versão, a questão é copiada: se for editada no banco depois, o histórico
/// não muda.
class RespostaQuestao {
  final String questaoId;
  final String materiaId;
  final String enunciado;

  /// Índice marcado pelo aluno na ordem impressa na versão.
  final int alternativaMarcada;

  /// Índice da alternativa certa na ordem impressa na versão.
  final int respostaCorreta;

  const RespostaQuestao({
    required this.questaoId,
    required this.materiaId,
    required this.enunciado,
    required this.alternativaMarcada,
    required this.respostaCorreta,
  });

  bool get correta => alternativaMarcada == respostaCorreta;
}

/// Uma folha corrigida: o resultado de uma versão de prova.
class Correcao {
  final String id;
  final String provaId;
  final String versaoId;
  final String provaNome;
  final String materia;
  final String? turma;
  final String? alunoId;
  final String? alunoNome;
  final DateTime corrigidoEm;
  final List<RespostaQuestao> respostas;

  const Correcao({
    required this.id,
    required this.provaId,
    required this.versaoId,
    required this.provaNome,
    required this.materia,
    required this.turma,
    required this.alunoId,
    required this.alunoNome,
    required this.corrigidoEm,
    required this.respostas,
  });

  int get acertos => respostas.where((r) => r.correta).length;
  int get total => respostas.length;

  /// Nota de 0 a 10; 0 se a prova não tem questões.
  double get nota => total == 0 ? 0 : acertos / total * 10;
}
