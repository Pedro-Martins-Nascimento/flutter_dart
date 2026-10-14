// Conversão entre os objetos de prova do app e os mapas guardados no
// Firestore. Não importa Firebase, então também funciona em memória e em testes.

import '../models/questao.dart';
import '../models/versao_prova.dart';
import 'provas_repository.dart' show ProvaGerada;

class ProvaMapper {
  const ProvaMapper._();

  // Documento professores/{uid}/provas/{provaId}.

  /// O `id` não entra: ele é o id do documento. As versões ficam na
  /// subcoleção `versoes`, porque uma prova com 40 versões passa de 400 KB e
  /// o limite do Firestore é 1 MiB por documento.
  static Map<String, dynamic> provaParaMapa(ProvaGerada prova) => {
    'nome': prova.nome,
    'materia': prova.materia,
    'turma': prova.turma,
    'criadoEm': prova.criadoEm,
    // Evita ler a subcoleção inteira só para mostrar "N versões" no histórico.
    'totalVersoes': prova.versoes.length,
  };

  static ProvaGerada provaDeMapa(
    String id,
    Map<String, dynamic> mapa, {
    required List<VersaoProva> versoes,
  }) => ProvaGerada(
    id: id,
    nome: mapa['nome'] as String,
    materia: mapa['materia'] as String,
    turma: mapa['turma'] as String?,
    criadoEm: _lerData(mapa['criadoEm']),
    versoes: versoes,
  );

  // Documento .../provas/{provaId}/versoes/{versaoId}.

  static Map<String, dynamic> versaoParaMapa(VersaoProva versao) => {
    'qrCode': versao.qrCode,
    'alunoId': versao.alunoId,
    'materia': versao.materia,
    'professor': versao.professor,
    'turma': versao.turma,
    'provaNome': versao.provaNome,
    'questoes': [for (final q in versao.questoes) _questaoParaMapa(q)],
  };

  static VersaoProva versaoDeMapa(String id, Map<String, dynamic> mapa) =>
      VersaoProva(
        id: id,
        qrCode: mapa['qrCode'] as String,
        alunoId: mapa['alunoId'] as String?,
        materia: mapa['materia'] as String,
        professor: mapa['professor'] as String,
        turma: mapa['turma'] as String?,
        provaNome: mapa['provaNome'] as String,
        questoes: [
          for (final q in (mapa['questoes'] as List))
            _questaoDeMapa(Map<String, dynamic>.from(q as Map)),
        ],
      );

  // A questão é copiada para dentro da versão: se for editada no banco
  // depois, as provas já impressas e o gabarito delas não mudam.

  static Map<String, dynamic> _questaoParaMapa(QuestaoNaVersao q) => {
    'questaoId': q.questao.id,
    'materiaId': q.questao.materiaId,
    'enunciado': q.questao.enunciado,
    'alternativasOriginais': q.questao.alternativas,
    'respostaOriginal': q.questao.respostaCorreta,
    // Ordem embaralhada impressa nesta versão e o índice certo nela.
    'alternativas': q.alternativas,
    'respostaCorreta': q.respostaCorreta,
  };

  static QuestaoNaVersao _questaoDeMapa(Map<String, dynamic> mapa) =>
      QuestaoNaVersao(
        questao: Questao(
          id: mapa['questaoId'] as String,
          materiaId: mapa['materiaId'] as String,
          enunciado: mapa['enunciado'] as String,
          alternativas: List<String>.from(
            mapa['alternativasOriginais'] as List,
          ),
          respostaCorreta: mapa['respostaOriginal'] as int,
        ),
        alternativas: List<String>.from(mapa['alternativas'] as List),
        respostaCorreta: mapa['respostaCorreta'] as int,
      );

  /// Aceita DateTime, texto ISO e Timestamp do Firestore (via `toDate()`),
  /// sem depender do pacote do Firebase.
  static DateTime _lerData(Object? valor) {
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.parse(valor);
    if (valor == null) throw ArgumentError('criadoEm ausente');
    return (valor as dynamic).toDate() as DateTime;
  }
}
