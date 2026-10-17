import 'package:flutter_dart/models/aluno.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/services/alunos_para_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final turmas = [
    Turma(
      id: 't1',
      nome: 'Turma A',
      alunos: [AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1')],
    ),
    Turma(id: 't2', nome: 'Turma vazia'),
  ];

  test('turma sem nome, desconhecida ou sem alunos cai nos alunos de teste', () {
    expect(alunosDaTurma(null, turmas), same(alunosMock));
    expect(alunosDaTurma('Outra turma', turmas), same(alunosMock));
    expect(alunosDaTurma('Turma vazia', turmas), same(alunosMock));
  });

  test('turma com alunos devolve os alunos dela', () {
    final lista = alunosDaTurma('Turma A', turmas);
    expect(lista.map((a) => a.id), ['a1']);
    expect(lista.first.nome, 'Ana');
  });
}
