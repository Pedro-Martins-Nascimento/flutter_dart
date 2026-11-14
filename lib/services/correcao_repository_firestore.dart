// Guarda as correções no Firestore, em professores/{uid}/correcoes/{id}.
// Cada professor só enxerga as próprias (ver firestore.rules).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/correcao.dart';
import 'correcao_mapper.dart';
import 'correcao_repository.dart';

class CorrecaoRepositoryFirestore implements CorrecaoRepository {
  CorrecaoRepositoryFirestore(FirebaseFirestore firestore, String? uid)
    : _colecao = (uid == null || uid.isEmpty)
          ? null
          : firestore
              .collection('professores')
              .doc(uid)
              .collection('correcoes');

  final CollectionReference<Map<String, dynamic>>? _colecao;

  Query<Map<String, dynamic>>? get _maisNovasPrimeiro =>
      _colecao?.orderBy('corrigidoEm', descending: true);

  List<Correcao> _converter(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      List.unmodifiable([
        for (final doc in snapshot.docs)
          CorrecaoMapper.deMapa(doc.id, doc.data()),
      ]);

  @override
  Future<void> salvar(Correcao correcao) async {
    final colecao = _colecao;
    if (colecao == null) {
      debugPrint('[CorrecaoRepositoryFirestore] salvar ignorado: sem professor logado');
      return;
    }
    final doc = colecao.doc(correcao.id);
    // Transação para não sobrescrever uma correção existente.
    await colecao.firestore.runTransaction((tx) async {
      if ((await tx.get(doc)).exists) {
        throw StateError('Já existe uma correção com id ${correcao.id}');
      }
      tx.set(doc, CorrecaoMapper.paraMapa(correcao));
    });
  }

  @override
  Future<List<Correcao>> listar() async {
    final query = _maisNovasPrimeiro;
    if (query == null) return const [];
    return _converter(await query.get());
  }

  @override
  Stream<List<Correcao>> observar() {
    final query = _maisNovasPrimeiro;
    if (query == null) return Stream.value(const []);
    return query.snapshots().map(_converter);
  }

  @override
  Future<Correcao?> buscar(String id) async {
    final colecao = _colecao;
    if (colecao == null) return null;
    final doc = await colecao.doc(id).get();
    final dados = doc.data();
    return dados == null ? null : CorrecaoMapper.deMapa(doc.id, dados);
  }

  @override
  Future<bool> jaCorrigida(String provaId, String versaoId) async {
    final colecao = _colecao;
    if (colecao == null) return false;
    final resultado = await colecao
        .where('provaId', isEqualTo: provaId)
        .where('versaoId', isEqualTo: versaoId)
        .limit(1)
        .get();
    return resultado.docs.isNotEmpty;
  }

  @override
  Future<void> excluir(String id) async {
    final colecao = _colecao;
    if (colecao == null) {
      debugPrint('[CorrecaoRepositoryFirestore] excluir ignorado: sem professor logado');
      return;
    }
    await colecao.doc(id).delete();
  }
}
