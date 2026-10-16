// Guarda as correções em memória, sem Firebase; os dados somem ao fechar o app.
//
// O que fica guardado são mapas, no mesmo formato do Firestore, e não os
// objetos, para o comportamento ser igual ao da versão com Firestore.

import 'dart:async';

import '../models/correcao.dart';
import 'correcao_mapper.dart';
import 'correcao_repository.dart';

class CorrecaoRepositoryMemoria implements CorrecaoRepository {
  final Map<String, Map<String, dynamic>> _correcoes = {};

  final StreamController<void> _mudancas = StreamController<void>.broadcast(
    sync: true,
  );

  List<Correcao> _lista() {
    final lista = [
      for (final e in _correcoes.entries) CorrecaoMapper.deMapa(e.key, e.value),
    ];
    lista.sort((a, b) => b.corrigidoEm.compareTo(a.corrigidoEm));
    return List.unmodifiable(lista);
  }

  @override
  Future<void> salvar(Correcao correcao) async {
    if (_correcoes.containsKey(correcao.id)) {
      throw StateError('Já existe uma correção com id ${correcao.id}');
    }
    _correcoes[correcao.id] = CorrecaoMapper.paraMapa(correcao);
    _mudancas.add(null);
  }

  @override
  Future<List<Correcao>> listar() async => _lista();

  @override
  Stream<List<Correcao>> observar() {
    late final StreamController<List<Correcao>> saida;
    StreamSubscription<void>? inscricao;
    saida = StreamController<List<Correcao>>(
      onListen: () {
        saida.add(_lista());
        inscricao = _mudancas.stream.listen((_) => saida.add(_lista()));
      },
      onCancel: () async {
        await inscricao?.cancel();
        await saida.close();
      },
    );
    return saida.stream;
  }

  @override
  Future<Correcao?> buscar(String id) async {
    final mapa = _correcoes[id];
    return mapa == null ? null : CorrecaoMapper.deMapa(id, mapa);
  }

  @override
  Future<bool> jaCorrigida(String provaId, String versaoId) async => _correcoes
      .values
      .any((m) => m['provaId'] == provaId && m['versaoId'] == versaoId);

  @override
  Future<void> excluir(String id) async {
    if (_correcoes.remove(id) == null) return;
    _mudancas.add(null);
  }
}
