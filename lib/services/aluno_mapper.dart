import '../models/aluno.dart';

class AlunoMapper {
  const AlunoMapper._();

  // Documento professores/{uid}/alunos/{alunoId}.

  static Map<String, dynamic> toMap(Aluno aluno) => {
    'nome': aluno.nome,
  };

  static Aluno fromMap(String id, Map<String, dynamic> mapa) => Aluno(
    id: id,
    nome: mapa['nome'] as String? ?? '',
  );
}
