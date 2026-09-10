// lib/services/correcoes_repository.dart
//
// Histórico de correções (RF16/RF17 — N1, em memória). A leitura do QR
// code (RF13) já é real, via mobile_scanner, em CorrigirScreen. O que
// falta pro fluxo fechar é a leitura das marcações (RF14/OMR) — isso
// ainda não existe de verdade, então CorrigirVersaoScreen simula a
// detecção e deixa o professor confirmar/corrigir cada alternativa antes
// de calcular a nota.

import 'package:flutter/foundation.dart';

import '../screens/provas/gerar_provas_screen.dart'; // VersaoProva

class RespostaQuestao {
  final int alternativaMarcada;
  final bool correta;

  RespostaQuestao({required this.alternativaMarcada, required this.correta});
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
}
