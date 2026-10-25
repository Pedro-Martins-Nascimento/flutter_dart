// CorrecaoRepository do professor logado. O repositório é criado antes do
// login, então o uid é lido a cada chamada e cada uma delega para o
// CorrecaoRepositoryFirestore daquele professor.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/correcao.dart';
import 'correcao_repository.dart';
import 'correcao_repository_firestore.dart';

class CorrecaoRepositoryDoProfessor implements CorrecaoRepository {
  CorrecaoRepositoryDoProfessor({required this.uid, this.firestore});

  final String Function() uid;
  final FirebaseFirestore? firestore;

  CorrecaoRepository get _repo => CorrecaoRepositoryFirestore(
    firestore ?? FirebaseFirestore.instance,
    uid(),
  );

  @override
  Future<void> salvar(Correcao correcao) => _repo.salvar(correcao);

  @override
  Future<List<Correcao>> listar() => _repo.listar();

  @override
  Stream<List<Correcao>> observar() => _repo.observar();

  @override
  Future<Correcao?> buscar(String id) => _repo.buscar(id);

  @override
  Future<bool> jaCorrigida(String provaId, String versaoId) =>
      _repo.jaCorrigida(provaId, versaoId);

  @override
  Future<void> excluir(String id) => _repo.excluir(id);
}
