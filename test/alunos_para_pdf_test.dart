import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/services/alunos_para_pdf.dart';
import 'package:flutter_dart/services/turma_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final disciplinas = [
    Disciplina(
      id: 'd1',
      nome: 'Matemática',
      turmas: [
        Turma(
          id: 't1',
          nome: 'Turma A',
          alunos: [AlunoTurma(id: 'a1', nome: 'Ana', matricula: '1')],
        ),
        Turma(
          id: 't2',
          nome: 'Turma B',
          alunos: [AlunoTurma(id: 'b1', nome: 'Bruno', matricula: '2')],
        ),
        Turma(id: 't3', nome: 'Turma vazia'),
      ],
    ),
    // Mesmo nome de turma em outra disciplina: não pode misturar.
    Disciplina(
      id: 'd2',
      nome: 'Física',
      turmas: [
        Turma(
          id: 'f1',
          nome: 'Turma A',
          alunos: [AlunoTurma(id: 'c1', nome: 'Caio', matricula: '3')],
        ),
      ],
    ),
  ];

  List<String> ids({String? disciplina, String? turma}) => [
    for (final a in alunosDaProva(
      disciplina: disciplina,
      turma: turma,
      disciplinas: disciplinas,
    ))
      a.id,
  ];

  test('prova nova: alunos só da turma daquela disciplina', () {
    expect(ids(disciplina: 'Matemática', turma: 'Turma A'), ['a1']);
    expect(ids(disciplina: 'Física', turma: 'Turma A'), ['c1']);
    expect(
      alunosDaProva(
        disciplina: 'Matemática',
        turma: 'Turma A',
        disciplinas: disciplinas,
      ).single.nome,
      'Ana',
    );
  });

  test('prova com disciplina e sem turma: alunos de todas as turmas', () {
    expect(ids(disciplina: 'Matemática'), ['a1', 'b1']);
  });

  test(
    'prova antiga (nome da disciplina no campo turma): toda a disciplina',
    () {
      expect(ids(turma: 'Matemática'), ['a1', 'b1']);
    },
  );

  test('sem correspondência ou sem alunos devolve lista vazia', () {
    expect(ids(), isEmpty);
    expect(ids(turma: 'Outra'), isEmpty);
    expect(ids(disciplina: 'Outra', turma: 'Turma A'), isEmpty);
    expect(ids(disciplina: 'Matemática', turma: 'Turma vazia'), isEmpty);
    expect(ids(disciplina: 'Matemática', turma: 'Turma Z'), isEmpty);
  });

  group('documento da disciplina no Firestore', () {
    test('formato antigo: alunos direto na disciplina viram a "Turma 1"', () {
      final d = TurmaMapper.disciplinaDeMapa('d9', {
        'nome': 'História',
        'alunos': [
          {'id': 'x1', 'nome': 'Xavier', 'matricula': '9'},
        ],
      });
      expect(d.turmas, hasLength(1));
      expect(d.turmas.single.nome, 'Turma 1');
      expect(d.turmas.single.id, TurmaMapper.idTurmaMigrada('d9'));
      expect(d.alunos.single.nome, 'Xavier');
    });

    test('formato antigo sem alunos fica sem turmas', () {
      final d = TurmaMapper.disciplinaDeMapa('d9', {'nome': 'História'});
      expect(d.turmas, isEmpty);
    });

    test('formato novo vai e volta igual', () {
      final original = disciplinas.first;
      final lida = TurmaMapper.disciplinaDeMapa(
        original.id,
        TurmaMapper.disciplinaParaMapa(original),
      );
      expect(lida.nome, 'Matemática');
      expect(lida.turmas.map((t) => t.nome), [
        'Turma A',
        'Turma B',
        'Turma vazia',
      ]);
      expect(lida.turmaPorNome('Turma B')!.alunos.single.matricula, '2');
    });
  });
}
