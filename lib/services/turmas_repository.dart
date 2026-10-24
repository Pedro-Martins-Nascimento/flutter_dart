// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/turma.dart';
import 'turma_mapper.dart';

class TurmasRepository extends ChangeNotifier {
  TurmasRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    List<Turma>? iniciais,
  })  : _auth = auth,
        _firestore = firestore {
    if (iniciais != null) {
      _turmas = List.of(iniciais);
      _modoMemoria = true;
    } else {
      _ouvirAuth();
    }
  }

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscricao;
  StreamSubscription<User?>? _authInscricao;
  List<Turma> _turmas = [];
  bool _modoMemoria = false;

  List<Turma> get turmas => List.unmodifiable(_turmas);

  FirebaseAuth get __auth {
    if (_auth != null) return _auth;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return FirebaseAuth.instance;
  }

  FirebaseFirestore? get __firestore {
    if (_firestore != null) return _firestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  void _ouvirAuth() {
    try {
      if (Firebase.apps.isEmpty) return;
      _authInscricao = __auth.authStateChanges().listen((usuario) {
        _inscricao?.cancel();
        if (usuario == null) {
          _turmas = [];
          notifyListeners();
        } else {
          _escutarFirestore(usuario.uid);
        }
      });
      final usuarioAtual = __auth.currentUser;
      if (usuarioAtual != null) {
        _escutarFirestore(usuarioAtual.uid);
      }
    } catch (_) {}
  }

  void _escutarFirestore(String uid) {
    try {
      final db = __firestore;
      if (db == null) return;
      _inscricao = db
          .collection('professores')
          .doc(uid)
          .collection('turmas')
          .snapshots()
          .listen((snapshot) {
        _turmas = [
          for (final doc in snapshot.docs)
            TurmaMapper.turmaDeMapa(doc.id, doc.data()),
        ];
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}
  }

  Turma? porId(String id) {
    for (final turma in _turmas) {
      if (turma.id == id) return turma;
    }
    return null;
  }

  Turma criar(String nome) {
    final id = 'turma_${DateTime.now().millisecondsSinceEpoch}';
    final turma = Turma(id: id, nome: nome);

    if (_modoMemoria) {
      _turmas.insert(0, turma);
      notifyListeners();
    } else {
      try {
        final uid = __auth.currentUser?.uid;
        final db = __firestore;
        if (uid != null && db != null) {
          db
              .collection('professores')
              .doc(uid)
              .collection('turmas')
              .doc(id)
              .set(TurmaMapper.turmaParaMapa(turma));
        } else {
          _turmas.insert(0, turma);
          notifyListeners();
        }
      } catch (_) {
        _turmas.insert(0, turma);
        notifyListeners();
      }
    }
    return turma;
  }

  void excluir(String id) {
    if (_modoMemoria) {
      _turmas.removeWhere((t) => t.id == id);
      notifyListeners();
    } else {
      try {
        final uid = __auth.currentUser?.uid;
        final db = __firestore;
        if (uid != null && db != null) {
          db
              .collection('professores')
              .doc(uid)
              .collection('turmas')
              .doc(id)
              .delete();
        } else {
          _turmas.removeWhere((t) => t.id == id);
          notifyListeners();
        }
      } catch (_) {
        _turmas.removeWhere((t) => t.id == id);
        notifyListeners();
      }
    }
  }

  Future<void> adicionarAlunos(String turmaId, List<AlunoTurma> alunos) async {
    final turma = porId(turmaId);
    if (turma == null) return;
    final atualizados = List<AlunoTurma>.from(turma.alunos)..addAll(alunos);
    await _atualizarAlunosTurma(turmaId, atualizados);
  }

  Future<void> atualizarAluno(String turmaId, AlunoTurma aluno) async {
    final turma = porId(turmaId);
    if (turma == null) return;
    final alunos = List<AlunoTurma>.from(turma.alunos);
    final indice = alunos.indexWhere((a) => a.id == aluno.id);
    if (indice < 0) return;
    alunos[indice] = aluno;
    await _atualizarAlunosTurma(turmaId, alunos);
  }

  Future<void> removerAluno(String turmaId, String alunoId) async {
    final turma = porId(turmaId);
    if (turma == null) return;
    final alunos = turma.alunos.where((a) => a.id != alunoId).toList();
    await _atualizarAlunosTurma(turmaId, alunos);
  }

  Future<void> _atualizarAlunosTurma(String turmaId, List<AlunoTurma> alunos) async {
    if (_modoMemoria) {
      final indice = _turmas.indexWhere((t) => t.id == turmaId);
      if (indice >= 0) {
        _turmas[indice] = Turma(
          id: _turmas[indice].id,
          nome: _turmas[indice].nome,
          qtdProvas: _turmas[indice].qtdProvas,
          alunos: alunos,
        );
        notifyListeners();
      }
    } else {
      try {
        final uid = __auth.currentUser?.uid ?? 'dev_professor';
        final db = __firestore;
        if (db != null) {
          await db
              .collection('professores')
              .doc(uid)
              .collection('turmas')
              .doc(turmaId)
              .set({
            'alunos': [
              for (final a in alunos)
                {'id': a.id, 'nome': a.nome, 'matricula': a.matricula},
            ],
          }, SetOptions(merge: true));
        } else {
          final indice = _turmas.indexWhere((t) => t.id == turmaId);
          if (indice >= 0) {
            _turmas[indice] = Turma(
              id: _turmas[indice].id,
              nome: _turmas[indice].nome,
              qtdProvas: _turmas[indice].qtdProvas,
              alunos: alunos,
            );
            notifyListeners();
          }
        }
      } catch (_) {
        final indice = _turmas.indexWhere((t) => t.id == turmaId);
        if (indice >= 0) {
          _turmas[indice] = Turma(
            id: _turmas[indice].id,
            nome: _turmas[indice].nome,
            qtdProvas: _turmas[indice].qtdProvas,
            alunos: alunos,
          );
          notifyListeners();
        }
        rethrow;
      }
    }
  }

  @override
  void dispose() {
    _authInscricao?.cancel();
    _inscricao?.cancel();
    super.dispose();
  }
}
