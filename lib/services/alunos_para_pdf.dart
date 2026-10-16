// Alunos usados para preencher o nome no PDF e no editor de layout.

import '../models/aluno.dart';
import '../models/turma.dart';

/// Alunos da turma de nome [nomeTurma] dentro de [turmas]. Se a turma não for
/// achada ou não tiver alunos, devolve os alunos de teste, como a tela de
/// gerar provas.
List<Aluno> alunosDaTurma(String? nomeTurma, List<Turma> turmas) {
  if (nomeTurma != null) {
    for (final turma in turmas) {
      if (turma.nome == nomeTurma && turma.alunos.isNotEmpty) {
        return [for (final a in turma.alunos) Aluno(id: a.id, nome: a.nome)];
      }
    }
  }
  return alunosMock;
}
