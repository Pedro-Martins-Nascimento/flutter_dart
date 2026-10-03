class Aluno {
  final String id;
  final String nome;

  Aluno({required this.id, required this.nome});
}

final List<Aluno> alunosMock = [
  Aluno(id: 'al1', nome: 'Bruno Oliveira'),
  Aluno(id: 'al2', nome: 'Carla Menezes'),
  Aluno(id: 'al3', nome: 'Diego Farias'),
];
