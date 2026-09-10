import 'package:flutter/foundation.dart';

import '../models/questao.dart';
import '../screens/provas/gerar_provas_screen.dart';
import '../screens/turmas/criar_turma_screen.dart' show turmasMock;

class ProvaGerada {
  final String id;
  final String nome;
  final String materia;
  final String? turma;
  final DateTime criadoEm;
  final List<VersaoProva> versoes;

  ProvaGerada({
    required this.id,
    required this.nome,
    required this.materia,
    required this.turma,
    required this.criadoEm,
    required this.versoes,
  });
}

class ProvasRepository extends ChangeNotifier {
  ProvasRepository._();
  static final ProvasRepository instance = ProvasRepository._();

  final List<ProvaGerada> _provas = _provasIniciais();

  List<ProvaGerada> get provas => List.unmodifiable(_provas.reversed);

  void salvar(ProvaGerada prova) {
    _provas.add(prova);
    notifyListeners();
  }

  void excluir(String id) {
    _provas.removeWhere((prova) => prova.id == id);
    notifyListeners();
  }
}

List<ProvaGerada> _provasIniciais() {
  final agora = DateTime.now();

  ProvaGerada montar({
    required String id,
    required String nome,
    required String materiaId,
    required int indiceTurma,
    required int quantasVersoes,
    required int diasAtras,
  }) {
    final materia = materiasMock.firstWhere((m) => m.id == materiaId);
    final turma = indiceTurma < turmasMock.length
        ? turmasMock[indiceTurma].nome
        : null;
    final questoes = questoesMock
        .where((q) => q.materiaId == materiaId)
        .toList();

    return ProvaGerada(
      id: id,
      nome: nome,
      materia: materia.nome,
      turma: turma,
      criadoEm: agora.subtract(Duration(days: diasAtras)),
      versoes: List.generate(quantasVersoes, (i) {
        final numero = i + 1;
        return VersaoProva(
          id: 'v$numero',
          qrCode: '${id.toUpperCase()}-V$numero',
          questoes: [
            for (final questao in questoes)
              QuestaoNaVersao(
                questao: questao,
                alternativas: questao.alternativas,
                respostaCorreta: questao.respostaCorreta,
              ),
          ],
          materia: materia.nome,
          turma: turma,
          provaNome: nome,
        );
      }),
    );
  }

  return [
    montar(
      id: 'pg_mock3',
      nome: 'Recuperação — Biologia',
      materiaId: 'mat3',
      indiceTurma: 2,
      quantasVersoes: 2,
      diasAtras: 21,
    ),
    montar(
      id: 'pg_mock2',
      nome: 'Avaliação de História',
      materiaId: 'mat2',
      indiceTurma: 1,
      quantasVersoes: 3,
      diasAtras: 9,
    ),
    montar(
      id: 'pg_mock1',
      nome: 'P1 — Matemática',
      materiaId: 'mat1',
      indiceTurma: 0,
      quantasVersoes: 4,
      diasAtras: 2,
    ),
  ];
}
