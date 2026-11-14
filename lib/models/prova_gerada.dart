import 'versao_prova.dart';

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
