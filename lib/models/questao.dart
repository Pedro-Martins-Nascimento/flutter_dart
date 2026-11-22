class Materia {
  final String id;
  final String nome;

  /// Disciplina a que a matéria pertence. Matérias criadas antes das
  /// disciplinas ficam sem (null) até serem movidas para uma.
  final String? disciplinaId;

  Materia({required this.id, required this.nome, this.disciplinaId});
}

class Questao {
  final String id;
  final String materiaId;
  final String enunciado;
  final List<String> alternativas;
  final int respostaCorreta;

  Questao({
    required this.id,
    required this.materiaId,
    required this.enunciado,
    required this.alternativas,
    required this.respostaCorreta,
  }) : assert(
         alternativas.length >= 2,
         'Toda questão precisa de pelo menos 2 alternativas',
       ),
       assert(
         respostaCorreta >= 0 && respostaCorreta < alternativas.length,
         'respostaCorreta precisa apontar pra uma alternativa que existe',
       );
}

String letraAlternativa(int indice) => String.fromCharCode(65 + indice);

/// Como as versões são montadas a partir das questões escolhidas.
class OpcoesProva {
  /// Cada versão tem as alternativas de cada questão numa ordem diferente.
  final bool embaralharAlternativas;

  /// Cada versão tem as questões numa ordem diferente.
  final bool embaralharQuestoes;

  /// Cada versão já sai com um aluno da turma vinculado.
  final bool vincularAlunos;

  const OpcoesProva({
    this.embaralharAlternativas = true,
    this.embaralharQuestoes = true,
    this.vincularAlunos = false,
  });
}
