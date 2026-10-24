import '../models/questao.dart';

class QuestaoMapper {
  const QuestaoMapper._();

  // Documento professores/{uid}/materias/{materiaId}.
  static Map<String, dynamic> materiaParaMapa(Materia materia) => {
    'nome': materia.nome,
  };

  // Retorna null se o documento estiver corrompido.
  static Materia? materiaDeMapa(String id, Map<String, dynamic> mapa) {
    final nome = mapa['nome'];
    if (nome is! String || nome.isEmpty) return null;
    return Materia(id: id, nome: nome);
  }

  // Documento professores/{uid}/questoes/{questaoId}.
  static Map<String, dynamic> questaoParaMapa(Questao questao) => {
    'materiaId': questao.materiaId,
    'enunciado': questao.enunciado,
    'alternativas': questao.alternativas,
    'respostaCorreta': questao.respostaCorreta,
  };

  // Retorna null se o documento estiver corrompido ou violar os asserts.
  static Questao? questaoDeMapa(String id, Map<String, dynamic> mapa) {
    try {
      final materiaId = mapa['materiaId'] as String?;
      final enunciado = mapa['enunciado'] as String?;
      final respostaCorreta = (mapa['respostaCorreta'] as num?)?.toInt();

      if (materiaId == null ||
          materiaId.isEmpty ||
          enunciado == null ||
          respostaCorreta == null) {
        return null;
      }

      final raw = mapa['alternativas'];
      if (raw is! List || raw.length < 2) return null;
      final alternativas = raw.cast<String>();

      return Questao(
        id: id,
        materiaId: materiaId,
        enunciado: enunciado,
        alternativas: alternativas,
        respostaCorreta: respostaCorreta,
      );
    } catch (_) {
      return null;
    }
  }
}
