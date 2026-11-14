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

    test('começa vazio sem dados no Firestore', () async {
      await _aguardar(repo);
      expect(repo.turmas, isEmpty);
    });

    test('carrega turmas do professor logado', () async {
      await firestore
          .collection('professores/prof1/turmas')
          .doc('t1')
          .set({'nome': 'Turma 1', 'qtdProvas': 2, 'alunos': []});
      await _aguardar(repo);

      expect(repo.turmas, hasLength(1));
      expect(repo.turmas.first.nome, 'Turma 1');
    });

    test('cria turma no Firestore no caminho do professor', () async {
      final criada = repo.criar('3º Ano A');
      await _aguardar(repo);

      final doc = await firestore
          .doc('professores/prof1/turmas/${criada.id}')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['nome'], '3º Ano A');
    });

    test('adiciona e atualiza alunos no Firestore', () async {
      final criada = repo.criar('3º Ano B');
      await _aguardar(repo);

      await repo.adicionarAlunos(criada.id, [
        AlunoTurma(id: 'a1', nome: 'Carlos', matricula: '123'),
      ]);

      final doc = await firestore
          .doc('professores/prof1/turmas/${criada.id}')
          .get();
      expect(doc.exists, isTrue);
      final alunos = doc.data()!['alunos'] as List;
      expect(alunos, hasLength(1));
      expect(alunos[0]['nome'], 'Carlos');
    });

    test('exclui turma do Firestore', () async {
      final criada = repo.criar('3º Ano C');
      await _aguardar(repo);

      repo.excluir(criada.id);
      await _aguardar(repo);

      final doc = await firestore
          .doc('professores/prof1/turmas/${criada.id}')
          .get();
      expect(doc.exists, isFalse);
    });

    test('um professor não enxerga nem altera turmas de outro', () async {
      repo.criar('Turma do Prof 1');
      await _aguardar(repo);

      final auth2 = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'prof2'),
      );
      final repo2 = TurmasRepository(auth: auth2, firestore: firestore);
      await _aguardar(repo2);

      expect(repo.turmas, hasLength(1));
      expect(repo2.turmas, isEmpty);

      // Prof 2 não altera turma do Prof 1
      final turmaProf1 = repo.turmas.first;
      await repo2.adicionarAlunos(turmaProf1.id, [
        AlunoTurma(id: 'invasor', nome: 'Invasor', matricula: '999'),
      ]);
      repo2.excluir(turmaProf1.id);
      await _aguardar(repo);

      final docProf1 = await firestore
          .doc('professores/prof1/turmas/${turmaProf1.id}')
          .get();
      expect(docProf1.exists, isTrue);
      expect(docProf1.data()!['alunos'], isEmpty);

      repo2.dispose();
    });

    test('sem login: leituras vazias e escritas ignoradas sem gravar no Firestore', () async {
      final authDeslogado = MockFirebaseAuth(signedIn: false);
      final repoDeslogado = TurmasRepository(
        auth: authDeslogado,
        firestore: firestore,
      );
      await _aguardar(repoDeslogado);

      expect(repoDeslogado.turmas, isEmpty);

      final turma = repoDeslogado.criar('Turma Fantasma');
      await repoDeslogado.adicionarAlunos(turma.id, [
        AlunoTurma(id: 'a1', nome: 'Aluno', matricula: '001'),
      ]);
      repoDeslogado.excluir(turma.id);

      await _aguardar(repoDeslogado);
      expect(repoDeslogado.turmas, isEmpty);

      // Nada foi gravado em 'professores'
      final snapshot = await firestore.collection('professores').get();
      expect(snapshot.docs, isEmpty);

      repoDeslogado.dispose();
    });

    test('logout limpa a lista de turmas', () async {
      repo.criar('Turma Temporária');
      await _aguardar(repo);
      expect(repo.turmas, hasLength(1));

      await auth.signOut();
      await _aguardar(repo);

      expect(repo.turmas, isEmpty);
    });
  });
}
