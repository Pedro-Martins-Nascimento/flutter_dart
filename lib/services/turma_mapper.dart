import '../models/turma.dart';

class TurmaMapper {
  const TurmaMapper._();

  // Documento professores/{uid}/turmas/{disciplinaId}. A coleção manteve o
  // nome antigo: cada documento é uma disciplina, com as turmas dentro.

  static Map<String, dynamic> disciplinaParaMapa(Disciplina disciplina) => {
    'nome': disciplina.nome,
    'qtdProvas': disciplina.qtdProvas,
    'turmas': turmasParaLista(disciplina.turmas),
  };

  static List<Map<String, dynamic>> turmasParaLista(List<Turma> turmas) => [
    for (final turma in turmas)
      {
        'id': turma.id,
        'nome': turma.nome,
        'alunos': _alunosParaLista(turma.alunos),
      },
  ];

  static List<Map<String, dynamic>> _alunosParaLista(List<AlunoTurma> alunos) =>
      [
        for (final aluno in alunos)
          {'id': aluno.id, 'nome': aluno.nome, 'matricula': aluno.matricula},
      ];

  /// Documentos antigos guardavam os alunos direto na disciplina, sem turmas.
  /// Esses alunos aparecem numa "Turma 1"; a próxima gravação de turmas já
  /// salva no formato novo e apaga a lista antiga.
  static Disciplina disciplinaDeMapa(String id, Map<String, dynamic> mapa) {
    final turmasGravadas = mapa['turmas'];
    final List<Turma> turmas;
    if (turmasGravadas is List) {
      turmas = [
        for (final item in turmasGravadas)
          if (item is Map)
            Turma(
              id: item['id'] as String? ?? '',
              nome: item['nome'] as String? ?? '',
              alunos: _alunosDeLista(item['alunos']),
            ),
      ];
    } else {
      final antigos = _alunosDeLista(mapa['alunos']);
      turmas = [
        if (antigos.isNotEmpty)
          Turma(id: idTurmaMigrada(id), nome: 'Turma 1', alunos: antigos),
      ];
    }
    return Disciplina(
      id: id,
      nome: mapa['nome'] as String? ?? '',
      qtdProvas: (mapa['qtdProvas'] as num?)?.toInt() ?? 0,
      turmas: turmas,
    );
  }

  /// Id fixo da turma criada a partir dos alunos antigos, para não mudar a
  /// cada leitura.
  static String idTurmaMigrada(String disciplinaId) => '${disciplinaId}_t1';

  static List<AlunoTurma> _alunosDeLista(Object? lista) => [
    if (lista is List)
      for (final item in lista)
        if (item is Map)
          AlunoTurma(
            id: item['id'] as String? ?? '',
            nome: item['nome'] as String? ?? '',
            matricula: item['matricula'] as String? ?? '',
          ),
  ];
}
