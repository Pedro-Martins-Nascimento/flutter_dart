import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/services/turmas_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _aguardar(TurmasRepository repo) async {
  final completer = Future<void>.delayed(Duration.zero);
  await completer;
  await completer;
}

void main() {
  group('TurmasRepository (Firestore)', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late TurmasRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'prof1'));
      repo = TurmasRepository(auth: auth, firestore: firestore);
    });

    tearDown(() => repo.dispose());

    Future<Map<String, dynamic>?> doc(String id) async =>
        (await firestore.doc('professores/prof1/turmas/$id').get()).data();

    test('começa vazio sem dados no Firestore', () async {
      await _aguardar(repo);
      expect(repo.disciplinas, isEmpty);
    });

    test('carrega disciplinas e turmas do professor logado', () async {
      await firestore.collection('professores/prof1/turmas').doc('d1').set({
        'nome': 'Matemática',
        'qtdProvas': 2,
        'turmas': [
          {
            'id': 't1',
            'nome': '3º ano A',
            'alunos': [
              {'id': 'a1', 'nome': 'Ana', 'matricula': '1'},
            ],
          },
        ],
      });
      await _aguardar(repo);

      expect(repo.disciplinas, hasLength(1));
      final disciplina = repo.disciplinas.single;
      expect(disciplina.nome, 'Matemática');
      expect(disciplina.turmas.single.nome, '3º ano A');
      expect(disciplina.alunos.single.nome, 'Ana');
    });

    test('cria disciplina no Firestore no caminho do professor', () async {
      final criada = repo.criarDisciplina('Matemática');
      await _aguardar(repo);

      final dados = await doc(criada.id);
      expect(dados!['nome'], 'Matemática');
      expect(dados['turmas'], isEmpty);
    });

    test('cria turma e adiciona alunos dentro da disciplina', () async {
      final disciplina = repo.criarDisciplina('Física');
      await _aguardar(repo);

      final turma = await repo.criarTurma(disciplina.id, '2º ano');
      await _aguardar(repo);
      await repo.adicionarAlunos(disciplina.id, turma!.id, [
        AlunoTurma(id: 'a1', nome: 'Carlos', matricula: '123'),
      ]);

      final turmas = (await doc(disciplina.id))!['turmas'] as List;
      expect(turmas, hasLength(1));
      expect(turmas[0]['nome'], '2º ano');
      expect((turmas[0]['alunos'] as List).single['nome'], 'Carlos');
    });

    test('disciplina antiga com alunos: aparecem na "Turma 1" e são '
        'regravados no formato novo', () async {
      await firestore.collection('professores/prof1/turmas').doc('d1').set({
        'nome': 'História',
        'alunos': [
          {'id': 'a1', 'nome': 'Ana', 'matricula': '1'},
        ],
      });
      await _aguardar(repo);

      final turma1 = repo.disciplinaPorId('d1')!.turmas.single;
      expect(turma1.nome, 'Turma 1');
      expect(turma1.alunos.single.nome, 'Ana');

      // Qualquer mudança nas turmas grava o formato novo e apaga o antigo.
      await repo.criarTurma('d1', 'Turma 2');
      await _aguardar(repo);

      final dados = (await doc('d1'))!;
      expect(dados.containsKey('alunos'), isFalse);
      final turmas = dados['turmas'] as List;
      expect(turmas.map((t) => t['nome']), ['Turma 1', 'Turma 2']);
      expect((turmas[0]['alunos'] as List).single['nome'], 'Ana');
    });

    test('exclui disciplina do Firestore', () async {
      final criada = repo.criarDisciplina('Química');
      await _aguardar(repo);

      repo.excluirDisciplina(criada.id);
      await _aguardar(repo);

      expect(await doc(criada.id), isNull);
    });

    test('um professor não enxerga nem altera disciplinas de outro', () async {
      final disciplina = repo.criarDisciplina('Do Prof 1');
      await _aguardar(repo);
      final turma = await repo.criarTurma(disciplina.id, 'Turma do Prof 1');
      await _aguardar(repo);

      final auth2 = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'prof2'),
      );
      final repo2 = TurmasRepository(auth: auth2, firestore: firestore);
      await _aguardar(repo2);

      expect(repo.disciplinas, hasLength(1));
      expect(repo2.disciplinas, isEmpty);

      await repo2.adicionarAlunos(disciplina.id, turma!.id, [
        AlunoTurma(id: 'invasor', nome: 'Invasor', matricula: '999'),
      ]);
      repo2.excluirDisciplina(disciplina.id);
      await _aguardar(repo);

      final dados = await doc(disciplina.id);
      expect(dados, isNotNull);
      final turmas = dados!['turmas'] as List;
      expect(turmas.single['alunos'], isEmpty);

      repo2.dispose();
    });

    test('sem login: leituras vazias e escritas ignoradas', () async {
      final authDeslogado = MockFirebaseAuth(signedIn: false);
      final repoDeslogado = TurmasRepository(
        auth: authDeslogado,
        firestore: firestore,
      );
      await _aguardar(repoDeslogado);

      expect(repoDeslogado.disciplinas, isEmpty);

      final disciplina = repoDeslogado.criarDisciplina('Fantasma');
      await repoDeslogado.criarTurma(disciplina.id, 'Turma');
      repoDeslogado.excluirDisciplina(disciplina.id);

      await _aguardar(repoDeslogado);
      expect(repoDeslogado.disciplinas, isEmpty);

      final snapshot = await firestore.collection('professores').get();
      expect(snapshot.docs, isEmpty);

      repoDeslogado.dispose();
    });

    test('logout limpa a lista de disciplinas', () async {
      repo.criarDisciplina('Temporária');
      await _aguardar(repo);
      expect(repo.disciplinas, hasLength(1));

      await auth.signOut();
      await _aguardar(repo);

      expect(repo.disciplinas, isEmpty);
    });
  });
}
