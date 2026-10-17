/// Uma linha do relatório de notas: um aluno em uma prova.
class LinhaNota {
  final String aluno;
  final String prova;

  /// null = sem nota (não corrigida ou faltou); sai como célula vazia no
  /// Excel, e não como 0.
  final double? nota;

  const LinhaNota({required this.aluno, required this.prova, this.nota});
}
