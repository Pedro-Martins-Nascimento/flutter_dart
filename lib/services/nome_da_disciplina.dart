// Nome da disciplina de uma questão, a partir do `materiaId` gravado nela e
// nas respostas das correções.

import '../models/turma.dart';
import 'questoes_repository.dart';

/// Função que dá o nome da disciplina de um `materiaId`: o id de uma
/// disciplina (questões novas) ou de uma matéria antiga, que vale pela
/// disciplina dela. Sem disciplina conhecida, "Sem disciplina".
String Function(String materiaId) nomeDaDisciplina(
  QuestoesRepository questoes,
  List<Disciplina> disciplinas,
) {
  final nomes = {for (final d in disciplinas) d.id: d.nome};
  return (materiaId) {
    final disciplinaId = questoes.disciplinaDoGrupo(materiaId);
    return nomes[disciplinaId] ?? 'Sem disciplina';
  };
}
