// lib/services/provas_repository.dart
//
// Histórico de "provas geradas" (N1 — em memória, sem Firebase ainda).
//


import '../screens/provas/gerar_provas_screen.dart'; // VersaoProva


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

class ProvasRepository {
  ProvasRepository._();
  static final ProvasRepository instance = ProvasRepository._();

  final List<ProvaGerada> _provas = [];

  List<ProvaGerada> get provas => List.unmodifiable(_provas.reversed);

  void salvar(ProvaGerada prova) {
    _provas.add(prova);
  }
}
