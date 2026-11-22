import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/services/turma_mapper.dart';

/// Disciplina gravada no formato antigo (alunos direto nela, sem turmas),
/// lida pelo mesmo caminho do Firestore: os alunos vão para a "Turma 1".
Disciplina disciplinaAntiga({
  required String id,
  required String nome,
  int qtdProvas = 0,
  List<AlunoTurma> alunos = const [],
}) => TurmaMapper.disciplinaDeMapa(id, {
  'nome': nome,
  'qtdProvas': qtdProvas,
  'alunos': [
    for (final a in alunos)
      {'id': a.id, 'nome': a.nome, 'matricula': a.matricula},
  ],
});
