// Conversão entre as correções do app e os mapas guardados no Firestore.
// Não importa Firebase, então também funciona em memória e em testes.

import '../models/correcao.dart';

class CorrecaoMapper {
  const CorrecaoMapper._();

  // Documento professores/{uid}/correcoes/{correcaoId}. O `id` não entra: ele
  // é o id do documento.

  static Map<String, dynamic> paraMapa(Correcao correcao) => {
    'provaId': correcao.provaId,
    'versaoId': correcao.versaoId,
    'provaNome': correcao.provaNome,
    'materia': correcao.materia,
    'turma': correcao.turma,
    'alunoId': correcao.alunoId,
    'alunoNome': correcao.alunoNome,
    'corrigidoEm': correcao.corrigidoEm,
    'respostas': [for (final r in correcao.respostas) _respostaParaMapa(r)],
  };

  static Correcao deMapa(String id, Map<String, dynamic> mapa) => Correcao(
    id: id,
    provaId: mapa['provaId'] as String,
    versaoId: mapa['versaoId'] as String,
    provaNome: mapa['provaNome'] as String,
    materia: mapa['materia'] as String,
    turma: mapa['turma'] as String?,
    alunoId: mapa['alunoId'] as String?,
    alunoNome: mapa['alunoNome'] as String?,
    corrigidoEm: _lerData(mapa['corrigidoEm']),
    respostas: [
      for (final r in (mapa['respostas'] as List))
        _respostaDeMapa(Map<String, dynamic>.from(r as Map)),
    ],
  );

  static Map<String, dynamic> _respostaParaMapa(RespostaQuestao r) => {
    'questaoId': r.questaoId,
    'materiaId': r.materiaId,
    'enunciado': r.enunciado,
    'alternativaMarcada': r.alternativaMarcada,
    'respostaCorreta': r.respostaCorreta,
  };

  static RespostaQuestao _respostaDeMapa(Map<String, dynamic> mapa) =>
      RespostaQuestao(
        questaoId: mapa['questaoId'] as String,
        materiaId: mapa['materiaId'] as String,
        enunciado: mapa['enunciado'] as String,
        alternativaMarcada: mapa['alternativaMarcada'] as int,
        respostaCorreta: mapa['respostaCorreta'] as int,
      );

  /// Aceita DateTime, texto ISO e Timestamp do Firestore (via `toDate()`),
  /// sem depender do pacote do Firebase.
  static DateTime _lerData(Object? valor) {
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.parse(valor);
    if (valor == null) throw ArgumentError('corrigidoEm ausente');
    return (valor as dynamic).toDate() as DateTime;
  }
}
