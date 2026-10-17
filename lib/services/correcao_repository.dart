// Contrato de armazenamento das correções (resultados). As telas e a
// estatística usam só esta interface, então trocar a implementação (memória,
// Firestore) não exige mexer nelas.

import '../models/correcao.dart';

abstract class CorrecaoRepository {
  /// Salva uma correção nova. O `id` vem de [correcao]. Lança [StateError] se
  /// já existir uma correção com esse id.
  Future<void> salvar(Correcao correcao);

  /// Histórico, da correção mais nova para a mais antiga.
  Future<List<Correcao>> listar();

  /// Igual a [listar], mas emite de novo a cada salvar/excluir.
  Stream<List<Correcao>> observar();

  /// Correção com o id dado, ou null se não existir.
  Future<Correcao?> buscar(String id);

  /// Se a versão da prova já tem alguma correção salva.
  Future<bool> jaCorrigida(String provaId, String versaoId);

  /// Remove a correção. Não faz nada se o id não existir.
  Future<void> excluir(String id);
}
