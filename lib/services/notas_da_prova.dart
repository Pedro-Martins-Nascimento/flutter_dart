// Monta as linhas do relatório de notas de uma prova: um aluno da turma por
// linha, com a nota da correção ou vazia se ainda não foi corrigido.

import '../models/correcao.dart';
import '../models/linha_nota.dart';
import '../models/turma.dart';
import 'alunos_para_pdf.dart';
import 'prova_repository.dart' show ProvaResumo;

List<LinhaNota> linhasDeNotas({
  required ProvaResumo prova,
  required List<Disciplina> disciplinas,
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

  final alunosDaTurma = alunosTurmaDaProva(
    disciplina: prova.disciplina,
    turma: prova.turma,
    disciplinas: disciplinas,
  );

  final linhas = <LinhaNota>[];
  for (final aluno in alunosDaTurma) {
    final c = porAluno.remove(aluno.id);
    linhas.add(
      LinhaNota(
        matricula: aluno.matricula,
        aluno: aluno.nome,
        nota: c?.nota,
        data: c?.corrigidoEm,
      ),
    );
  }

  // Correções de quem não está na turma e folhas sem aluno vinculado.
  for (final c in [...porAluno.values, ...semAluno]) {
    linhas.add(
      LinhaNota(
        aluno: c.alunoNome ?? 'Sem aluno vinculado (${c.versaoId})',
        nota: c.nota,
        data: c.corrigidoEm,
      ),
    );
  }
  return linhas;
}
