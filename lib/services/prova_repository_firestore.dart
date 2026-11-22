// ProvaRepository gravando no Firestore:
//   professores/{uid}/provas/{provaId}
//   professores/{uid}/provas/{provaId}/versoes/{versaoId}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/versao_prova.dart';
import 'prova_mapper.dart';
import 'prova_repository.dart';
import '../models/prova_gerada.dart';

class ProvaRepositoryFirestore implements ProvaRepository {
  /// [uid] é lido a cada chamada, porque o repositório é criado antes do login.
  ProvaRepositoryFirestore({required this.uid, this.firestore});

  final String? Function() uid;
  final FirebaseFirestore? firestore;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? get _provas {
    final u = uid();
    if (u == null || u.isEmpty) return null;
    return _db.collection('professores').doc(u).collection('provas');
  }

  CollectionReference<Map<String, dynamic>>? _versoes(String provaId) {
    final colecao = _provas;
    if (colecao == null) return null;
    return colecao.doc(provaId).collection('versoes');
  }

  ProvaResumo _resumo(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ProvaResumo(
      id: doc.id,
      nome: d['nome'] as String,
      materia: d['materia'] as String,
      turma: d['turma'] as String?,
      disciplina: d['disciplina'] as String?,
      criadoEm: (d['criadoEm'] as Timestamp).toDate(),
      totalVersoes: d['totalVersoes'] as int,
    );
  }

  // `ordem` mantém v1, v2, ..., v10 na sequência (o id ordena como texto).
  void _gravarVersoes(WriteBatch lote, ProvaGerada prova, CollectionReference<Map<String, dynamic>> versoesCol) {
    for (var i = 0; i < prova.versoes.length; i++) {
      final v = prova.versoes[i];
      lote.set(versoesCol.doc(v.id), {
        ...ProvaMapper.versaoParaMapa(v),
        'ordem': i,
      });
    }
  }

  @override
  Future<void> criar(ProvaGerada prova) async {
    final colecao = _provas;
    if (colecao == null) {
      debugPrint('[ProvaRepositoryFirestore] criar ignorado: sem professor logado');
      return;
    }
    final ref = colecao.doc(prova.id);
    if ((await ref.get()).exists) {
      throw StateError('Já existe uma prova com id ${prova.id}');
    }
    final lote = _db.batch()..set(ref, ProvaMapper.provaParaMapa(prova));
    _gravarVersoes(lote, prova, _versoes(prova.id)!);
    await lote.commit();
  }

  @override
  Future<List<ProvaResumo>> listar() async {
    final colecao = _provas;
    if (colecao == null) return const [];
    final consulta = await colecao.orderBy('criadoEm', descending: true).get();
    return [for (final doc in consulta.docs) _resumo(doc)];
  }

  @override
  Stream<List<ProvaResumo>> observar() {
    final colecao = _provas;
    if (colecao == null) return Stream.value(const []);
    return colecao
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((s) => [for (final doc in s.docs) _resumo(doc)]);
  }

  @override
  Future<ProvaGerada?> buscar(String id) async {
    final colecao = _provas;
    if (colecao == null) return null;
    final doc = await colecao.doc(id).get();
    if (!doc.exists) return null;
    final versoes = await _versoes(id)!.orderBy('ordem').get();
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
    final colecao = _provas;
    if (colecao == null) {
      debugPrint('[ProvaRepositoryFirestore] editar ignorado: sem professor logado');
      return;
    }
    final ref = colecao.doc(prova.id);
    if (!(await ref.get()).exists) {
      throw StateError('Prova ${prova.id} não existe');
    }
    final versoesCol = _versoes(prova.id)!;
    final antigas = await versoesCol.get();
    final lote = _db.batch();
    // Só apaga as que saíram da prova; as demais são regravadas abaixo.
    final mantidas = {for (final v in prova.versoes) v.id};
    for (final v in antigas.docs) {
      if (!mantidas.contains(v.id)) lote.delete(v.reference);
    }
    lote.set(ref, ProvaMapper.provaParaMapa(prova));
    _gravarVersoes(lote, prova, versoesCol);
    await lote.commit();
  }

  @override
  Future<void> atualizarVersao(String provaId, VersaoProva versao) async {
    final versoesCol = _versoes(provaId);
    if (versoesCol == null) {
      debugPrint('[ProvaRepositoryFirestore] atualizarVersao ignorado: sem professor logado');
      return;
    }
    try {
      await versoesCol
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
    final colecao = _provas;
    if (colecao == null) {
      debugPrint('[ProvaRepositoryFirestore] excluir ignorado: sem professor logado');
      return;
    }
    final versoesCol = _versoes(id)!;
    final versoes = await versoesCol.get();
    final lote = _db.batch();
    for (final v in versoes.docs) {
      lote.delete(v.reference);
    }
    lote.delete(colecao.doc(id));
    await lote.commit();
  }
}
