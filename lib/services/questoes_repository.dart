import 'package:flutter/foundation.dart';

import '../models/questao.dart';

class QuestoesRepository extends ChangeNotifier {
  QuestoesRepository({List<Materia>? materias, List<Questao>? questoes})
    : _materias = List.of(materias ?? materiasMock),
      _questoes = List.of(questoes ?? questoesMock);

  final List<Materia> _materias;
  final List<Questao> _questoes;

  List<Materia> get materias => List.unmodifiable(_materias);
  List<Questao> get questoes => List.unmodifiable(_questoes);

  Materia? materiaPorId(String id) {
    for (final materia in _materias) {
      if (materia.id == id) return materia;
    }
    return null;
  }

  List<Questao> questoesDaMateria(String materiaId) =>
      _questoes.where((q) => q.materiaId == materiaId).toList();

  void criarMateria(String nome) {
    _materias.add(
      Materia(id: 'mat_${DateTime.now().millisecondsSinceEpoch}', nome: nome),
    );
    notifyListeners();
  }

  void excluirMateria(String id) {
    _questoes.removeWhere((q) => q.materiaId == id);
    _materias.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void salvarQuestao(Questao questao) {
    final indice = _questoes.indexWhere((q) => q.id == questao.id);
    if (indice >= 0) {
      _questoes[indice] = questao;
    } else {
      _questoes.add(questao);
    }
    notifyListeners();
  }

  void excluirQuestao(String id) {
    _questoes.removeWhere((q) => q.id == id);
    notifyListeners();
  }
}
