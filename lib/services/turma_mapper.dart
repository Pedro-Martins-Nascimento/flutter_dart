import '../models/turma.dart';

class TurmaMapper {
  const TurmaMapper._();

  // Documento professores/{uid}/turmas/{turmaId}.

  static Map<String, dynamic> turmaParaMapa(Turma turma) => {
    'nome': turma.nome,
    'qtdProvas': turma.qtdProvas,
    'alunos': [
      for (final aluno in turma.alunos)
        {
          'id': aluno.id,
          'nome': aluno.nome,
          'matricula': aluno.matricula,
        },
    ],
  };

  static Turma turmaDeMapa(String id, Map<String, dynamic> mapa) => Turma(
    id: id,
    nome: mapa['nome'] as String? ?? '',
    qtdProvas: (mapa['qtdProvas'] as num?)?.toInt() ?? 0,
    alunos: [
      if (mapa['alunos'] is List)
        for (final item in (mapa['alunos'] as List))
          if (item is Map)
            AlunoTurma(
              id: item['id'] as String? ?? '',
              nome: item['nome'] as String? ?? '',
              matricula: item['matricula'] as String? ?? '',
            ),
    ],
  );
}
