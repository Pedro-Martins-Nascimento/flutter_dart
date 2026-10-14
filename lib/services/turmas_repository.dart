import 'package:flutter/foundation.dart';

import '../models/turma.dart';

class TurmasRepository extends ChangeNotifier {
  TurmasRepository({List<Turma>? iniciais})
    : _turmas = List.of(iniciais ?? turmasMock);

  final List<Turma> _turmas;

  List<Turma> get turmas => List.unmodifiable(_turmas);

  Turma? porId(String id) {
    for (final turma in _turmas) {
      if (turma.id == id) return turma;
    }
    return null;
  }

  Turma criar(String nome) {
    final turma = Turma(
      id: 'turma_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome,
    );
    _turmas.insert(0, turma);
    notifyListeners();
    return turma;
  }

  void excluir(String id) {
    _turmas.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void adicionarAlunos(String turmaId, List<AlunoTurma> alunos) {
    final turma = porId(turmaId);
    if (turma == null) return;
    turma.alunos.addAll(alunos);
    notifyListeners();
  }

  void atualizarAluno(String turmaId, AlunoTurma aluno) {
    final alunos = porId(turmaId)?.alunos;
    if (alunos == null) return;
    final indice = alunos.indexWhere((a) => a.id == aluno.id);
    if (indice < 0) return;
    alunos[indice] = aluno;
    notifyListeners();
  }

  void removerAluno(String turmaId, String alunoId) {
    porId(turmaId)?.alunos.removeWhere((a) => a.id == alunoId);
    notifyListeners();
  }
}
