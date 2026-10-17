// Guarda as correções no Firestore, em professores/{uid}/correcoes/{id}.
// Cada professor só enxerga as próprias (ver firestore.rules).

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/correcao.dart';
import 'correcao_mapper.dart';
import 'correcao_repository.dart';

class CorrecaoRepositoryFirestore implements CorrecaoRepository {
  CorrecaoRepositoryFirestore(FirebaseFirestore firestore, String uid)
    : _colecao = firestore
          .collection('professores')
          .doc(uid)
          .collection('correcoes');

  final CollectionReference<Map<String, dynamic>> _colecao;

  Query<Map<String, dynamic>> get _maisNovasPrimeiro =>
      _colecao.orderBy('corrigidoEm', descending: true);

  List<Correcao> _converter(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      List.unmodifiable([
        for (final doc in snapshot.docs)
          CorrecaoMapper.deMapa(doc.id, doc.data()),
      ]);

  @override
  Future<void> salvar(Correcao correcao) async {
    final doc = _colecao.doc(correcao.id);
    // Transação para não sobrescrever uma correção existente.
    await _colecao.firestore.runTransaction((tx) async {
      if ((await tx.get(doc)).exists) {
        throw StateError('Já existe uma correção com id ${correcao.id}');
      }
      tx.set(doc, CorrecaoMapper.paraMapa(correcao));
    });
  }

  @override
  Future<List<Correcao>> listar() async =>
      _converter(await _maisNovasPrimeiro.get());

  @override
  Stream<List<Correcao>> observar() =>
      _maisNovasPrimeiro.snapshots().map(_converter);

  @override
  Future<Correcao?> buscar(String id) async {
    final doc = await _colecao.doc(id).get();
    final dados = doc.data();
    return dados == null ? null : CorrecaoMapper.deMapa(doc.id, dados);
  }

  @override
  Future<bool> jaCorrigida(String provaId, String versaoId) async {
    final resultado = await _colecao
        .where('provaId', isEqualTo: provaId)
        .where('versaoId', isEqualTo: versaoId)
        .limit(1)
        .get();
    return resultado.docs.isNotEmpty;
  }

  @override
  Future<void> excluir(String id) => _colecao.doc(id).delete();
}
