// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/questao.dart';
import 'questao_mapper.dart';

class QuestoesRepository extends ChangeNotifier {
  QuestoesRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    List<Materia>? materias,
    List<Questao>? questoes,
  })  : _auth = auth,
        _firestore = firestore,
        _authExplicito = auth != null {
    if (materias != null || questoes != null) {
      _materias = List.of(materias ?? []);
      _questoes = List.of(questoes ?? []);
      _modoMemoria = true;
    } else {
      _ouvirAuth();
    }
  }

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final bool _authExplicito;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscricaoMaterias;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscricaoQuestoes;
  StreamSubscription<User?>? _authInscricao;

  List<Materia> _materias = [];
  List<Questao> _questoes = [];
  bool _modoMemoria = false;

  List<Materia> get materias => List.unmodifiable(_materias);
  List<Questao> get questoes => List.unmodifiable(_questoes);

  Materia? materiaPorId(String id) {
    for (final m in _materias) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<Questao> questoesDaMateria(String materiaId) =>
      _questoes.where((q) => q.materiaId == materiaId).toList();

  // ---------- helpers privados ----------

  FirebaseAuth get __auth {
    if (_auth != null) return _auth;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return FirebaseAuth.instance;
  }

  FirebaseFirestore? get __firestore {
    if (_firestore != null) return _firestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  void _ouvirAuth() {
    try {
      if (!_authExplicito && Firebase.apps.isEmpty) return;
      _authInscricao = __auth.authStateChanges().listen((usuario) {
        _inscricaoMaterias?.cancel();
        _inscricaoQuestoes?.cancel();
        if (usuario == null) {
          _materias = [];
          _questoes = [];
          notifyListeners();
        } else {
          _escutarFirestore(usuario.uid);
        }
      });
      final atual = __auth.currentUser;
      if (atual != null) _escutarFirestore(atual.uid);
    } catch (_) {}
  }

  void _escutarFirestore(String uid) {
    final db = __firestore;
    if (db == null) return;

    try {
      _inscricaoMaterias = db
          .collection('professores')
          .doc(uid)
          .collection('materias')
          .snapshots()
          .listen((snap) {
        _materias = snap.docs
            .map((doc) => QuestaoMapper.materiaDeMapa(doc.id, doc.data()))
            .whereType<Materia>()
            .toList();
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}

    try {
      _inscricaoQuestoes = db
          .collection('professores')
          .doc(uid)
          .collection('questoes')
          .snapshots()
          .listen((snap) {
        _questoes = snap.docs
            .map((doc) => QuestaoMapper.questaoDeMapa(doc.id, doc.data()))
            .whereType<Questao>()
            .toList();
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}
  }

  // ---------- operações de escrita ----------

  void criarMateria(String nome) {
    if (_modoMemoria) {
      _materias.add(
        Materia(id: 'mat_${DateTime.now().millisecondsSinceEpoch}', nome: nome),
      );
      notifyListeners();
      return;
    }

    final uid = __auth.currentUser?.uid;
    final db = __firestore;
    if (uid == null || db == null) return;

    final id = 'mat_${DateTime.now().millisecondsSinceEpoch}';
    final materia = Materia(id: id, nome: nome);
    db
        .collection('professores')
        .doc(uid)
        .collection('materias')
        .doc(id)
        .set(QuestaoMapper.materiaParaMapa(materia))
        .catchError(
          (e) => debugPrint('[QuestoesRepository] criarMateria: $e'),
        );
  }

  void excluirMateria(String id) {
    if (_modoMemoria) {
      _questoes.removeWhere((q) => q.materiaId == id);
      _materias.removeWhere((m) => m.id == id);
      notifyListeners();
      return;
    }

    final uid = __auth.currentUser?.uid;
    final db = __firestore;
    if (uid == null || db == null) return;

    // Apaga matéria + questões dela de forma atômica.
    final batch = db.batch();
    batch.delete(
      db.collection('professores').doc(uid).collection('materias').doc(id),
    );
    for (final q in _questoes.where((q) => q.materiaId == id)) {
      batch.delete(
        db.collection('professores').doc(uid).collection('questoes').doc(q.id),
      );
    }
    batch.commit().catchError(
      (e) => debugPrint('[QuestoesRepository] excluirMateria: $e'),
    );
  }

  void salvarQuestao(Questao questao) {
    if (_modoMemoria) {
      final i = _questoes.indexWhere((q) => q.id == questao.id);
      if (i >= 0) {
        _questoes[i] = questao;
      } else {
        _questoes.add(questao);
      }
      notifyListeners();
      return;
    }

    final uid = __auth.currentUser?.uid;
    final db = __firestore;
    if (uid == null || db == null) return;

    db
        .collection('professores')
        .doc(uid)
        .collection('questoes')
        .doc(questao.id)
        .set(QuestaoMapper.questaoParaMapa(questao))
        .catchError(
          (e) => debugPrint('[QuestoesRepository] salvarQuestao: $e'),
        );
  }

  void excluirQuestao(String id) {
    if (_modoMemoria) {
      _questoes.removeWhere((q) => q.id == id);
      notifyListeners();
      return;
    }

    final uid = __auth.currentUser?.uid;
    final db = __firestore;
    if (uid == null || db == null) return;

    db
        .collection('professores')
        .doc(uid)
        .collection('questoes')
        .doc(id)
        .delete()
        .catchError(
          (e) => debugPrint('[QuestoesRepository] excluirQuestao: $e'),
        );
  }

  @override
  void dispose() {
    _authInscricao?.cancel();
    _inscricaoMaterias?.cancel();
    _inscricaoQuestoes?.cancel();
    super.dispose();
  }
}
