// ProvaRepository gravando no Firestore:
//   professores/{uid}/provas/{provaId}
//   professores/{uid}/provas/{provaId}/versoes/{versaoId}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/versao_prova.dart';
import 'prova_mapper.dart';
import 'prova_repository.dart';
import 'provas_repository.dart' show ProvaGerada;

class ProvaRepositoryFirestore implements ProvaRepository {
  /// [uid] é lido a cada chamada, porque o repositório é criado antes do login.
  ProvaRepositoryFirestore({required this.uid, this.firestore});

  final String Function() uid;
  final FirebaseFirestore? firestore;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _provas =>
      _db.collection('professores').doc(uid()).collection('provas');

  CollectionReference<Map<String, dynamic>> _versoes(String provaId) =>
      _provas.doc(provaId).collection('versoes');

  ProvaResumo _resumo(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ProvaResumo(
      id: doc.id,
      nome: d['nome'] as String,
      materia: d['materia'] as String,
      turma: d['turma'] as String?,
      criadoEm: (d['criadoEm'] as Timestamp).toDate(),
      totalVersoes: d['totalVersoes'] as int,
    );
  }

  // `ordem` mantém v1, v2, ..., v10 na sequência (o id ordena como texto).
  void _gravarVersoes(WriteBatch lote, ProvaGerada prova) {
    for (var i = 0; i < prova.versoes.length; i++) {
      final v = prova.versoes[i];
      lote.set(_versoes(prova.id).doc(v.id), {
        ...ProvaMapper.versaoParaMapa(v),
        'ordem': i,
      });
    }
  }

  @override
  Future<void> criar(ProvaGerada prova) async {
    final ref = _provas.doc(prova.id);
    if ((await ref.get()).exists) {
      throw StateError('Já existe uma prova com id ${prova.id}');
    }
    final lote = _db.batch()..set(ref, ProvaMapper.provaParaMapa(prova));
    _gravarVersoes(lote, prova);
    await lote.commit();
  }

  @override
  Future<List<ProvaResumo>> listar() async {
    final consulta = await _provas.orderBy('criadoEm', descending: true).get();
    return [for (final doc in consulta.docs) _resumo(doc)];
  }

  @override
  Stream<List<ProvaResumo>> observar() => _provas
      .orderBy('criadoEm', descending: true)
      .snapshots()
      .map((s) => [for (final doc in s.docs) _resumo(doc)]);

  @override
  Future<ProvaGerada?> buscar(String id) async {
    final doc = await _provas.doc(id).get();
    if (!doc.exists) return null;
    final versoes = await _versoes(id).orderBy('ordem').get();
    return ProvaMapper.provaDeMapa(
      id,
      doc.data()!,
      versoes: [
        for (final v in versoes.docs) ProvaMapper.versaoDeMapa(v.id, v.data()),
      ],
    );
  }

  @override
  Future<void> editar(ProvaGerada prova) async {
    final ref = _provas.doc(prova.id);
    if (!(await ref.get()).exists) {
      throw StateError('Prova ${prova.id} não existe');
    }
    final antigas = await _versoes(prova.id).get();
    final lote = _db.batch();
    for (final v in antigas.docs) {
      lote.delete(v.reference);
    }
    lote.set(ref, ProvaMapper.provaParaMapa(prova));
    _gravarVersoes(lote, prova);
    await lote.commit();
  }

  @override
  Future<void> atualizarVersao(String provaId, VersaoProva versao) async {
    try {
      await _versoes(provaId)
          .doc(versao.id)
          .update(ProvaMapper.versaoParaMapa(versao));
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw StateError('Versão ${versao.id} da prova $provaId não existe');
      }
      rethrow;
    }
  }

  @override
  Future<void> excluir(String id) async {
    final versoes = await _versoes(id).get();
    final lote = _db.batch();
    for (final v in versoes.docs) {
      lote.delete(v.reference);
    }
    lote.delete(_provas.doc(id));
    await lote.commit();
  }
}
