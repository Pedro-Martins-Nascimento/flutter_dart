class Materia {
  final String id;
  final String nome;

  Materia({required this.id, required this.nome});
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

enum ModoProva { mesmaEmbaralhada, conjuntosDiferentes }
