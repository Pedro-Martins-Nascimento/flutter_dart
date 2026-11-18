/// Uma linha do relatório de notas: um aluno em uma prova.
class LinhaNota {
  /// Vazia para folha corrigida sem aluno vinculado.
  final String matricula;
  final String aluno;

  /// null = sem nota (não corrigida ou faltou); sai como célula vazia no
  /// Excel, e não como 0.
  final double? nota;

  /// Dia em que a folha foi corrigida; null quando não há correção.
  final DateTime? data;

  const LinhaNota({
    this.matricula = '',
    required this.aluno,
    this.nota,
    this.data,
  });
}
