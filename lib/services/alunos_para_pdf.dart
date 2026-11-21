// Alunos de uma prova: usados para vincular as versões, preencher o nome no
// PDF e montar o relatório de notas.

import '../models/aluno.dart';
import '../models/turma.dart';

/// Alunos da turma da prova, achada pelos nomes gravados nela.
///
/// Provas novas têm [disciplina] e [turma]: valem os alunos daquela turma.
/// Provas antigas, de antes das turmas, têm só [turma] com o nome da
/// disciplina: valem os alunos de todas as turmas dela. Sem correspondência,
/// a lista vem vazia.
List<AlunoTurma> alunosTurmaDaProva({
  required String? disciplina,
  required String? turma,
  required List<Disciplina> disciplinas,
}) {
  Disciplina? porNome(String nome) {
    for (final d in disciplinas) {
      if (d.nome == nome) return d;
    }
    return null;
  }

  if (disciplina != null) {
    final achada = porNome(disciplina);
    if (achada == null) return const [];
    if (turma == null) return achada.alunos;
    return achada.turmaPorNome(turma)?.alunos ?? const [];
  }
  if (turma == null) return const [];
  return porNome(turma)?.alunos ?? const [];
}

/// O mesmo que [alunosTurmaDaProva], no formato usado pelo PDF.
List<Aluno> alunosDaProva({
  required String? disciplina,
  required String? turma,
  required List<Disciplina> disciplinas,
}) => [
  for (final a in alunosTurmaDaProva(
    disciplina: disciplina,
    turma: turma,
    disciplinas: disciplinas,
  ))
    Aluno(id: a.id, nome: a.nome),
];
