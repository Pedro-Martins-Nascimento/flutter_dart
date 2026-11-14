class AlunoTurma {
  final String id;
  final String nome;
  final String matricula;

  AlunoTurma({required this.id, required this.nome, required this.matricula});
}

class Turma {
  final String id;
  final String nome;
  final int qtdProvas;
  final List<AlunoTurma> alunos;

  Turma({
    required this.id,
    required this.nome,
    this.qtdProvas = 0,
    List<AlunoTurma>? alunos,
  }) : alunos = alunos ?? [];

  int get qtdAlunos => alunos.length;
}
