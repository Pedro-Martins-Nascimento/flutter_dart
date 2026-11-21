import 'versao_prova.dart';

class ProvaGerada {
  final String id;
  final String nome;
  final String materia;
  /// Nome da turma da prova. Provas antigas, de antes das turmas dentro
  /// das disciplinas, guardam aqui o nome da disciplina e [disciplina] fica
  /// null.
  final String? turma;

  /// Nome da disciplina da prova (null em provas antigas).
  final String? disciplina;
  final DateTime criadoEm;
  final List<VersaoProva> versoes;

  ProvaGerada({
    required this.id,
    required this.nome,
    required this.materia,
    required this.turma,
    this.disciplina,
    required this.criadoEm,
    required this.versoes,
  });
}
