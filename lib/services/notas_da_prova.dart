// Monta as linhas do relatório de notas de uma prova: um aluno da turma por
// linha, com a nota da correção ou vazia se ainda não foi corrigido.

import '../models/correcao.dart';
import '../models/linha_nota.dart';
import '../models/turma.dart';
import 'prova_repository.dart' show ProvaResumo;

List<LinhaNota> linhasDeNotas({
  required ProvaResumo prova,
  required List<Turma> turmas,
  required List<Correcao> correcoes,
}) {
  // Se o aluno tem mais de uma correção na prova, vale a mais recente.
  final porAluno = <String, Correcao>{};
  final semAluno = <Correcao>[];
  for (final c in correcoes.where((c) => c.provaId == prova.id)) {
    final alunoId = c.alunoId;
    if (alunoId == null) {
      semAluno.add(c);
      continue;
    }
    final atual = porAluno[alunoId];
    if (atual == null || c.corrigidoEm.isAfter(atual.corrigidoEm)) {
      porAluno[alunoId] = c;
    }
  }

  final alunosDaTurma = [
    for (final turma in turmas)
      if (turma.nome == prova.turma) ...turma.alunos,
  ];

  final linhas = <LinhaNota>[];
  for (final aluno in alunosDaTurma) {
    linhas.add(
      LinhaNota(
        aluno: aluno.nome,
        prova: prova.nome,
        nota: porAluno.remove(aluno.id)?.nota,
      ),
    );
  }

  // Correções de quem não está na turma e folhas sem aluno vinculado.
  for (final c in [...porAluno.values, ...semAluno]) {
    linhas.add(
      LinhaNota(
        aluno: c.alunoNome ?? 'Sem aluno vinculado (${c.versaoId})',
        prova: prova.nome,
        nota: c.nota,
      ),
    );
  }
  return linhas;
}
