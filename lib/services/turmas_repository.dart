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
    List<Disciplina>? iniciais,
  }) : _auth = auth,
       _firestore = firestore,
       _authExplicito = auth != null {
    if (iniciais != null) {
      _disciplinas = List.of(iniciais);
      _modoMemoria = true;
    } else {
      _ouvirAuth();
    }
  }

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final bool _authExplicito;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscricao;
  StreamSubscription<User?>? _authInscricao;
  List<Disciplina> _disciplinas = [];
  bool _modoMemoria = false;

  /// Disciplinas do professor, cada uma com as suas turmas.
  List<Disciplina> get disciplinas => List.unmodifiable(_disciplinas);

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
      if (!_authExplicito && Firebase.apps.isEmpty) return;
      _authInscricao = __auth.authStateChanges().listen((usuario) {
        _inscricao?.cancel();
        if (usuario == null) {
          _disciplinas = [];
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
            _disciplinas = [
              for (final doc in snapshot.docs)
                TurmaMapper.disciplinaDeMapa(doc.id, doc.data()),
            ];
            notifyListeners();
          }, onError: (_) {});
    } catch (_) {}
  }

  Disciplina? disciplinaPorId(String id) {
    for (final disciplina in _disciplinas) {
      if (disciplina.id == id) return disciplina;
    }
    return null;
  }

  Disciplina? disciplinaPorNome(String nome) {
    for (final disciplina in _disciplinas) {
      if (disciplina.nome == nome) return disciplina;
    }
    return null;
  }

  Disciplina criarDisciplina(String nome) {
    final id = 'turma_${DateTime.now().millisecondsSinceEpoch}';
    final disciplina = Disciplina(id: id, nome: nome);
    _gravar(
      'criarDisciplina',
      local: () => _disciplinas.insert(0, disciplina),
      remoto: (doc) => doc(id).set(TurmaMapper.disciplinaParaMapa(disciplina)),
    );
    return disciplina;
  }

  void excluirDisciplina(String id) {
    if (disciplinaPorId(id) == null) return;
    _gravar(
      'excluirDisciplina',
      local: () => _disciplinas.removeWhere((d) => d.id == id),
      remoto: (doc) => doc(id).delete(),
    );
  }

  /// Cria uma turma vazia na disciplina. Devolve null se a disciplina não
  /// existe.
  Future<Turma?> criarTurma(String disciplinaId, String nome) async {
    final disciplina = disciplinaPorId(disciplinaId);
    if (disciplina == null) return null;
    final turma = Turma(
      id: 'turma_${DateTime.now().microsecondsSinceEpoch}',
      nome: nome,
    );
    await _salvarTurmas(disciplina, [...disciplina.turmas, turma]);
    return turma;
  }

  Future<void> excluirTurma(String disciplinaId, String turmaId) async {
    final disciplina = disciplinaPorId(disciplinaId);
    if (disciplina == null) return;
    await _salvarTurmas(disciplina, [
      for (final t in disciplina.turmas)
        if (t.id != turmaId) t,
    ]);
  }

  Future<void> adicionarAlunos(
    String disciplinaId,
    String turmaId,
    List<AlunoTurma> alunos,
  ) => _mudarAlunos(disciplinaId, turmaId, (atuais) => [...atuais, ...alunos]);

  Future<void> atualizarAluno(
    String disciplinaId,
    String turmaId,
    AlunoTurma aluno,
  ) => _mudarAlunos(disciplinaId, turmaId, (atuais) {
    final indice = atuais.indexWhere((a) => a.id == aluno.id);
    if (indice < 0) return null;
    return List.of(atuais)..[indice] = aluno;
  });

  Future<void> removerAluno(
    String disciplinaId,
    String turmaId,
    String alunoId,
  ) => _mudarAlunos(
    disciplinaId,
    turmaId,
    (atuais) => [
      for (final a in atuais)
        if (a.id != alunoId) a,
    ],
  );

  /// [mudar] recebe os alunos atuais e devolve a lista nova (ou null para
  /// não mudar nada).
  Future<void> _mudarAlunos(
    String disciplinaId,
    String turmaId,
    List<AlunoTurma>? Function(List<AlunoTurma> atuais) mudar,
  ) async {
    final disciplina = disciplinaPorId(disciplinaId);
    final turma = disciplina?.turmaPorId(turmaId);
    if (disciplina == null || turma == null) return;
    final novos = mudar(turma.alunos);
    if (novos == null) return;
    await _salvarTurmas(disciplina, [
      for (final t in disciplina.turmas)
        t.id == turmaId ? t.copiar(alunos: novos) : t,
    ]);
  }

  /// Grava a lista de turmas da disciplina. Apaga o campo `alunos` antigo:
  /// os alunos dele já estão na "Turma 1" (ver [TurmaMapper.disciplinaDeMapa]).
  Future<void> _salvarTurmas(Disciplina disciplina, List<Turma> turmas) {
    return _gravar(
      'salvarTurmas',
      local: () {
        final indice = _disciplinas.indexWhere((d) => d.id == disciplina.id);
        if (indice >= 0) {
          _disciplinas[indice] = _disciplinas[indice].copiar(turmas: turmas);
        }
      },
      remoto: (doc) => doc(disciplina.id).set({
        'turmas': TurmaMapper.turmasParaLista(turmas),
        'alunos': FieldValue.delete(),
      }, SetOptions(merge: true)),
      esperar: true,
    );
  }

  /// Em memória (testes) ou sem Firestore, muda a lista local e avisa as
  /// telas. Com Firestore, grava lá e a tela atualiza pelo snapshot. Se a
  /// gravação falhar de imediato, aplica local para não sumir da tela.
  Future<void> _gravar(
    String operacao, {
    required void Function() local,
    required Future<void> Function(
      DocumentReference<Map<String, dynamic>> Function(String id) doc,
    )
    remoto,
    bool esperar = false,
  }) async {
    void aplicarLocal() {
      local();
      notifyListeners();
    }

    if (_modoMemoria) return aplicarLocal();
    try {
      final uid = __auth.currentUser?.uid;
      final db = __firestore;
      if (db == null) return aplicarLocal();
      if (uid == null) {
        debugPrint(
          '[TurmasRepository] $operacao ignorado: sem professor logado',
        );
        return;
      }
      final colecao = db
          .collection('professores')
          .doc(uid)
          .collection('turmas');
      final gravacao = remoto(colecao.doc);
      if (esperar) {
        await gravacao;
      } else {
        unawaited(
          gravacao.catchError(
            (Object e) => debugPrint('[TurmasRepository] $operacao: $e'),
          ),
        );
      }
    } catch (e) {
      debugPrint('[TurmasRepository] $operacao: $e');
      aplicarLocal();
      if (esperar) rethrow;
    }
  }

  @override
  void dispose() {
    _authInscricao?.cancel();
    _inscricao?.cancel();
    super.dispose();
  }
}
