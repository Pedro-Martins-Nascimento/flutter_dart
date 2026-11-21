class AlunoTurma {
  final String id;
  final String nome;
  final String matricula;

  AlunoTurma({required this.id, required this.nome, required this.matricula});
}

/// Turma de uma disciplina: é ela que tem os alunos.
class Turma {
  final String id;
  final String nome;
  final List<AlunoTurma> alunos;

  Turma({required this.id, required this.nome, List<AlunoTurma>? alunos})
    : alunos = alunos ?? [];

  int get qtdAlunos => alunos.length;

  Turma copiar({String? nome, List<AlunoTurma>? alunos}) =>
      Turma(id: id, nome: nome ?? this.nome, alunos: alunos ?? this.alunos);
}

/// Disciplina do professor (ex.: "Matemática — 3º ano"), com as suas turmas.
class Disciplina {
  final String id;
  final String nome;
  final int qtdProvas;
  final List<Turma> turmas;

  Disciplina({
    required this.id,
    required this.nome,
    this.qtdProvas = 0,
    List<Turma>? turmas,
  }) : turmas = turmas ?? [];

  /// Alunos de todas as turmas, na ordem das turmas.
  List<AlunoTurma> get alunos => [for (final t in turmas) ...t.alunos];

  int get qtdAlunos => alunos.length;

  Turma? turmaPorId(String id) {
    for (final turma in turmas) {
      if (turma.id == id) return turma;
    }
    return null;
  }

  Turma? turmaPorNome(String nome) {
    for (final turma in turmas) {
      if (turma.nome == nome) return turma;
    }
    return null;
  }

  Disciplina copiar({List<Turma>? turmas}) => Disciplina(
    id: id,
    nome: nome,
    qtdProvas: qtdProvas,
    turmas: turmas ?? this.turmas,
  );
}
