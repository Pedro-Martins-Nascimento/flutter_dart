// Guarda as provas em memória, sem Firebase; os dados somem ao fechar o app.
//
// O que fica guardado são mapas, no mesmo formato do Firestore, e não os
// objetos: quem lê recebe uma cópia, e mexer nela não altera o repositório sem
// chamar editar/atualizarVersao.

import 'dart:async';

import '../models/versao_prova.dart';
import 'prova_mapper.dart';
import 'prova_repository.dart';
import 'provas_repository.dart' show ProvaGerada, ProvasRepository;

class ProvaRepositoryMemoria implements ProvaRepository {
  ProvaRepositoryMemoria();

  /// Já começa com as provas de exemplo de [ProvasRepository]. Sai quando o
  /// histórico passar a vir do Firestore.
  factory ProvaRepositoryMemoria.comMocks() {
    final repo = ProvaRepositoryMemoria();
    for (final prova in ProvasRepository.instance.provas) {
      repo._gravar(prova);
    }
    return repo;
  }

  final Map<String, Map<String, dynamic>> _provas = {};
  // Mapa literal preserva a ordem de inserção, então as versões voltam em
  // ordem (v1, v2, ...).
  final Map<String, Map<String, Map<String, dynamic>>> _versoes = {};

  final StreamController<void> _mudancas = StreamController<void>.broadcast(
    sync: true,
  );

  void _gravar(ProvaGerada prova) {
    _provas[prova.id] = ProvaMapper.provaParaMapa(prova);
    _versoes[prova.id] = {
      for (final v in prova.versoes) v.id: ProvaMapper.versaoParaMapa(v),
    };
  }

  List<ProvaResumo> _resumos() {
    final lista = [
      for (final e in _provas.entries)
        ProvaResumo(
          id: e.key,
          nome: e.value['nome'] as String,
          materia: e.value['materia'] as String,
          turma: e.value['turma'] as String?,
          criadoEm: e.value['criadoEm'] as DateTime,
          totalVersoes: e.value['totalVersoes'] as int,
        ),
    ];
    lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return List.unmodifiable(lista);
  }

  @override
  Future<void> criar(ProvaGerada prova) async {
    if (_provas.containsKey(prova.id)) {
      throw StateError('Já existe uma prova com id ${prova.id}');
    }
    _gravar(prova);
    _mudancas.add(null);
  }

  @override
  Future<List<ProvaResumo>> listar() async => _resumos();

  @override
  Stream<List<ProvaResumo>> observar() {
    late final StreamController<List<ProvaResumo>> saida;
    StreamSubscription<void>? inscricao;
    saida = StreamController<List<ProvaResumo>>(
      onListen: () {
        saida.add(_resumos());
        inscricao = _mudancas.stream.listen((_) => saida.add(_resumos()));
      },
      onCancel: () => inscricao?.cancel(),
    );
    return saida.stream;
  }

  @override
  Future<ProvaGerada?> buscar(String id) async {
    final mapa = _provas[id];
    if (mapa == null) return null;
    return ProvaMapper.provaDeMapa(
      id,
      mapa,
      versoes: [
        for (final e in _versoes[id]!.entries)
          ProvaMapper.versaoDeMapa(e.key, e.value),
      ],
    );
  }

  @override
  Future<void> editar(ProvaGerada prova) async {
    if (!_provas.containsKey(prova.id)) {
      throw StateError('Prova ${prova.id} não existe');
    }
    _gravar(prova);
    _mudancas.add(null);
  }

  @override
  Future<void> atualizarVersao(String provaId, VersaoProva versao) async {
    final versoes = _versoes[provaId];
    if (versoes == null || !versoes.containsKey(versao.id)) {
      throw StateError('Versão ${versao.id} da prova $provaId não existe');
    }
    versoes[versao.id] = ProvaMapper.versaoParaMapa(versao);
    _mudancas.add(null);
  }

  @override
  Future<void> excluir(String id) async {
    if (_provas.remove(id) == null) return;
    _versoes.remove(id);
    _mudancas.add(null);
  }
}
