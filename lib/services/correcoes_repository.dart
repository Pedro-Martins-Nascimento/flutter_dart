// lib/services/correcoes_repository.dart
//
// Histórico de correções (RF16/RF17 — N1, em memória). A leitura do QR
// code (RF13) já é real, via mobile_scanner, em CorrigirScreen. O que
// falta pro fluxo fechar é a leitura das marcações (RF14/OMR) — isso
// ainda não existe de verdade, então CorrigirVersaoScreen simula a
// detecção e deixa o professor confirmar/corrigir cada alternativa antes
// de calcular a nota.

import 'package:flutter/foundation.dart';

import '../models/questao.dart';
import '../screens/provas/gerar_provas_screen.dart'; // VersaoProva
import 'persistencia_service.dart';

class RespostaQuestao {
  final int alternativaMarcada;
  final bool correta;

  RespostaQuestao({required this.alternativaMarcada, required this.correta});

  Map<String, dynamic> toJson() => {
    'alternativaMarcada': alternativaMarcada,
    'correta': correta,
  };

  factory RespostaQuestao.fromJson(Map<String, dynamic> json) => RespostaQuestao(
    alternativaMarcada: json['alternativaMarcada'] as int,
    correta: json['correta'] as bool,
  );
}

class Correcao {
  final String id;
  final VersaoProva versao;
  final String provaNome;
  final String materia;
  final String? turma;
  final String? alunoNome;
  final DateTime corrigidoEm;
  final List<RespostaQuestao> respostas;

  Correcao({
    required this.id,
    required this.versao,
    required this.provaNome,
    required this.materia,
    required this.turma,
    required this.alunoNome,
    required this.corrigidoEm,
    required this.respostas,
  });

  int get acertos => respostas.where((r) => r.correta).length;
  int get total => respostas.length;
  double get nota => total == 0 ? 0 : (acertos / total) * 10;

  Map<String, dynamic> toJson() => {
    'id': id,
    'versao': versao.toJson(),
    'provaNome': provaNome,
    'materia': materia,
    'turma': turma,
    'alunoNome': alunoNome,
    'corrigidoEm': corrigidoEm.toIso8601String(),
    'respostas': respostas.map((r) => r.toJson()).toList(),
  };

  factory Correcao.fromJson(Map<String, dynamic> json) => Correcao(
    id: json['id'] as String,
    versao: VersaoProva.fromJson(json['versao'] as Map<String, dynamic>),
    provaNome: json['provaNome'] as String,
    materia: json['materia'] as String,
    turma: json['turma'] as String?,
    alunoNome: json['alunoNome'] as String?,
    corrigidoEm: DateTime.parse(json['corrigidoEm'] as String),
    respostas: (json['respostas'] as List)
        .map((r) => RespostaQuestao.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}

class CorrecoesRepository extends ChangeNotifier {
  CorrecoesRepository._();
  static final CorrecoesRepository instance = CorrecoesRepository._();

  final List<Correcao> _correcoes = [];

  List<Correcao> get correcoes => List.unmodifiable(_correcoes.reversed);

  bool jaCorrigida(String versaoId) =>
      _correcoes.any((c) => c.versao.id == versaoId);

  void salvar(Correcao correcao) {
    _correcoes.add(correcao);
    notifyListeners();
    PersistenciaService.instance.salvar();
  }

  @visibleForTesting
  void limparParaTeste() {
    _correcoes.clear();
    notifyListeners();
  }

  // Ordem de inserção original (não invertida como `correcoes`) — é o
  // formato salvo/restaurado pelo PersistenciaService.
  List<Correcao> exportarParaPersistencia() => List.unmodifiable(_correcoes);

  void importarDePersistencia(List<Correcao> correcoes) {
    _correcoes
      ..clear()
      ..addAll(correcoes);
  }

  double get mediaGeral {
    if (_correcoes.isEmpty) return 0;
    final soma = _correcoes.fold<double>(0, (acc, c) => acc + c.nota);
    return soma / _correcoes.length;
  }

  // Percentual de acerto por matéria, agregado entre todas as correções
  // já feitas — usado pelo card "Erro por matéria" da tela Início.
  Map<String, double> percentualAcertoPorMateria() {
    final acertos = <String, int>{};
    final totais = <String, int>{};

    for (final correcao in _correcoes) {
      for (var i = 0; i < correcao.respostas.length; i++) {
        final materiaId = correcao.versao.questoes[i].questao.materiaId;
        totais[materiaId] = (totais[materiaId] ?? 0) + 1;
        if (correcao.respostas[i].correta) {
          acertos[materiaId] = (acertos[materiaId] ?? 0) + 1;
        }
      }
    }

    return {
      for (final materiaId in totais.keys)
        materiaId: (acertos[materiaId] ?? 0) / totais[materiaId]! * 100,
    };
  }

  // Percentual de acerto por questão do banco (RF18) — usado na tela de
  // estatística completa pra achar as questões que mais derrubam a turma,
  // já com o enunciado (não só o id) pra facilitar a leitura.
  Map<Questao, double> percentualAcertoPorQuestao() {
    final acertos = <String, int>{};
    final totais = <String, int>{};
    final questoes = <String, Questao>{};

    for (final correcao in _correcoes) {
      for (var i = 0; i < correcao.respostas.length; i++) {
        final questao = correcao.versao.questoes[i].questao;
        totais[questao.id] = (totais[questao.id] ?? 0) + 1;
        questoes[questao.id] = questao;
        if (correcao.respostas[i].correta) {
          acertos[questao.id] = (acertos[questao.id] ?? 0) + 1;
        }
      }
    }

    return {
      for (final id in totais.keys)
        questoes[id]!: (acertos[id] ?? 0) / totais[id]! * 100,
    };
  }

  // Ranking de alunos por média (RF17/RF18) — só entra quem tem correção
  // com aluno vinculado; ordenado do melhor pro pior.
  List<({String aluno, double media, int quantidade})> rankingAlunos() {
    final porAluno = <String, List<Correcao>>{};
    for (final correcao in _correcoes) {
      final nome = correcao.alunoNome;
      if (nome == null) continue;
      porAluno.putIfAbsent(nome, () => []).add(correcao);
    }

    final ranking = [
      for (final entry in porAluno.entries)
        (
          aluno: entry.key,
          media: entry.value.fold<double>(0, (acc, c) => acc + c.nota) / entry.value.length,
          quantidade: entry.value.length,
        ),
    ]..sort((a, b) => b.media.compareTo(a.media));

    return ranking;
  }

  // Correções agrupadas por prova (pelo nome — é o que a Correcao guarda)
  // — usado na tela de estatística completa pra mostrar a média por prova.
  Map<String, List<Correcao>> porNomeDeProva() {
    final grupos = <String, List<Correcao>>{};
    for (final correcao in _correcoes) {
      grupos.putIfAbsent(correcao.provaNome, () => []).add(correcao);
    }
    return grupos;
  }
}
