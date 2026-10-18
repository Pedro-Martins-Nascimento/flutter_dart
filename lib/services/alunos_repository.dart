// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/aluno.dart';
import 'aluno_mapper.dart';

class AlunosRepository extends ChangeNotifier {
  AlunosRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    List<Aluno>? iniciais,
  })  : _auth = auth,
        _firestore = firestore {
    if (iniciais != null) {
      _alunos = List.of(iniciais);
      _modoMemoria = true;
    } else {
      _ouvirAuth();
    }
  }

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscricao;
  StreamSubscription<User?>? _authInscricao;
  List<Aluno> _alunos = [];
  bool _modoMemoria = false;

  List<Aluno> get alunos => List.unmodifiable(_alunos);

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
        final uid = usuario?.uid ?? 'dev_professor';
        _escutarFirestore(uid);
      });
      final usuarioAtual = __auth.currentUser;
      final uid = usuarioAtual?.uid ?? 'dev_professor';
      _escutarFirestore(uid);
    } catch (_) {}
  }

  void _escutarFirestore(String uid) {
    try {
      final db = __firestore;
      if (db == null) return;
      _inscricao = db
          .collection('professores')
          .doc(uid)
          .collection('alunos')
          .snapshots()
          .listen((snapshot) {
        _alunos = [
          for (final doc in snapshot.docs)
            AlunoMapper.fromMap(doc.id, doc.data()),
        ];
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}
  }

  Aluno? porId(String id) {
    for (final aluno in _alunos) {
      if (aluno.id == id) return aluno;
    }
    return null;
  }

  Future<Aluno> adicionar(String nome) async {
    if (_modoMemoria) {
      final aluno = Aluno(
        id: 'aluno_${DateTime.now().millisecondsSinceEpoch}',
        nome: nome,
      );
      _alunos.insert(0, aluno);
      notifyListeners();
      return aluno;
    } else {
      try {
        final uid = __auth.currentUser?.uid ?? 'dev_professor';
        final db = __firestore;
        if (db != null) {
          final docRef = db
              .collection('professores')
              .doc(uid)
              .collection('alunos')
              .doc();
          final aluno = Aluno(id: docRef.id, nome: nome);
          await docRef.set(AlunoMapper.toMap(aluno));
          return aluno;
        } else {
          final aluno = Aluno(
            id: 'aluno_${DateTime.now().millisecondsSinceEpoch}',
            nome: nome,
          );
          _alunos.insert(0, aluno);
          notifyListeners();
          return aluno;
        }
      } catch (_) {
        final aluno = Aluno(
          id: 'aluno_${DateTime.now().millisecondsSinceEpoch}',
          nome: nome,
        );
        _alunos.insert(0, aluno);
        notifyListeners();
        return aluno;
      }
    }
  }

  Future<void> adicionarLote(List<String> nomes) async {
    for (final nome in nomes) {
      if (nome.trim().isNotEmpty) {
        await adicionar(nome.trim());
      }
    }
  }

  Future<void> excluir(String id) async {
    if (_modoMemoria) {
      _alunos.removeWhere((a) => a.id == id);
      notifyListeners();
    } else {
      try {
        final uid = __auth.currentUser?.uid ?? 'dev_professor';
        final db = __firestore;
        if (db != null) {
          await db
              .collection('professores')
              .doc(uid)
              .collection('alunos')
              .doc(id)
              .delete();
        } else {
          _alunos.removeWhere((a) => a.id == id);
          notifyListeners();
        }
      } catch (_) {
        _alunos.removeWhere((a) => a.id == id);
        notifyListeners();
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
