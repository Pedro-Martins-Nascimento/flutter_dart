// Contrato de armazenamento das provas. As telas usam só esta interface, então
// trocar a implementação (memória, Firestore) não exige mexer nelas.

import '../models/versao_prova.dart';
import 'provas_repository.dart' show ProvaGerada;

/// Dados de uma prova para o histórico: tudo menos as versões.
///
/// As versões ficam numa subcoleção e são pesadas, então a lista traz só o
/// resumo e a prova completa vem de [ProvaRepository.buscar] ao abrir.
class ProvaResumo {
  final String id;
  final String nome;
  final String materia;
  final String? turma;
  final DateTime criadoEm;
  final int totalVersoes;

  const ProvaResumo({
    required this.id,
    required this.nome,
    required this.materia,
    required this.turma,
    required this.criadoEm,
    required this.totalVersoes,
  });

  factory ProvaResumo.de(ProvaGerada prova) => ProvaResumo(
    id: prova.id,
    nome: prova.nome,
    materia: prova.materia,
    turma: prova.turma,
    criadoEm: prova.criadoEm,
    totalVersoes: prova.versoes.length,
  );
}

abstract class ProvaRepository {
  /// Salva uma prova nova com todas as versões. O `id` vem de [prova].
  Future<void> criar(ProvaGerada prova);

  /// Histórico, da prova mais nova para a mais antiga.
  Future<List<ProvaResumo>> listar();

  /// Igual a [listar], mas emite de novo a cada criar/editar/excluir.
  Stream<List<ProvaResumo>> observar();

  /// Prova completa com as versões, ou null se não existir.
  Future<ProvaGerada?> buscar(String id);

  /// Regrava a prova inteira. Lança [StateError] se o id não existir.
  Future<void> editar(ProvaGerada prova);

  /// Regrava só uma versão (ex.: ao vincular um aluno), sem tocar nas outras.
  /// Lança [StateError] se a prova ou a versão não existir.
  Future<void> atualizarVersao(String provaId, VersaoProva versao);

  /// Remove a prova e suas versões. Não faz nada se o id não existir.
  Future<void> excluir(String id);
}
