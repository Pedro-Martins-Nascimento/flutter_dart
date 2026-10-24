import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/services/questoes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper: aguarda o repositório emitir ao menos uma notificação.
Future<void> _aguardar(QuestoesRepository repo) async {
  final completer = Future<void>.delayed(Duration.zero);
  await completer;
  await completer;
}

Questao _questao(String id, String materiaId) => Questao(
  id: id,
  materiaId: materiaId,
  enunciado: 'Enunciado $id',
  alternativas: const ['A', 'B'],
  respostaCorreta: 0,
);

void main() {
  group('QuestoesRepository (Firestore)', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late QuestoesRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'prof1'));
      repo = QuestoesRepository(auth: auth, firestore: firestore);
    });

    tearDown(() => repo.dispose());

    test('começa vazio sem dados no Firestore', () async {
      await _aguardar(repo);
      expect(repo.materias, isEmpty);
      expect(repo.questoes, isEmpty);
    });

    test('carrega matérias e questões do professor logado', () async {
      await firestore
          .collection('professores/prof1/materias')
          .doc('m1')
          .set({'nome': 'Matemática'});
      await firestore
          .collection('professores/prof1/questoes')
          .doc('q1')
          .set({
            'materiaId': 'm1',
            'enunciado': 'Quanto é 2+2?',
            'alternativas': ['3', '4'],
            'respostaCorreta': 1,
          });
      await _aguardar(repo);

      expect(repo.materias, hasLength(1));
      expect(repo.materias.first.nome, 'Matemática');
      expect(repo.questoes, hasLength(1));
      expect(repo.questoes.first.enunciado, 'Quanto é 2+2?');
    });

    test('criarMateria grava no Firestore e aparece no snapshot', () async {
      repo.criarMateria('História');
      await _aguardar(repo);

      final snap = await firestore
          .collection('professores/prof1/materias')
          .get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['nome'], 'História');
      expect(repo.materias.map((m) => m.nome), contains('História'));
    });

    test('salvarQuestao cria nova questão', () async {
      await firestore
          .collection('professores/prof1/materias')
          .doc('m1')
          .set({'nome': 'Física'});
      await _aguardar(repo);

      repo.salvarQuestao(_questao('q1', 'm1'));
      await _aguardar(repo);

      expect(repo.questoesDaMateria('m1'), hasLength(1));
      final doc = await firestore
          .doc('professores/prof1/questoes/q1')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['enunciado'], 'Enunciado q1');
    });

    test('salvarQuestao atualiza questão existente', () async {
      await firestore
          .collection('professores/prof1/materias')
          .doc('m1')
          .set({'nome': 'Física'});
      repo.salvarQuestao(_questao('q1', 'm1'));
      await _aguardar(repo);

      // Atualiza com novo enunciado.
      repo.salvarQuestao(
        Questao(
          id: 'q1',
          materiaId: 'm1',
          enunciado: 'Enunciado atualizado',
          alternativas: const ['A', 'B'],
          respostaCorreta: 0,
        ),
      );
      await _aguardar(repo);

      final doc = await firestore.doc('professores/prof1/questoes/q1').get();
      expect(doc.data()!['enunciado'], 'Enunciado atualizado');
    });

    test('excluirQuestao remove do Firestore', () async {
      await firestore
          .collection('professores/prof1/questoes')
          .doc('q1')
          .set({
            'materiaId': 'm1',
            'enunciado': 'X',
            'alternativas': ['A', 'B'],
            'respostaCorreta': 0,
          });
      await _aguardar(repo);
      expect(repo.questoes, hasLength(1));

      repo.excluirQuestao('q1');
      await _aguardar(repo);

      expect(repo.questoes, isEmpty);
      expect(
        (await firestore.doc('professores/prof1/questoes/q1').get()).exists,
        isFalse,
      );
    });

    test('excluirMateria apaga a matéria e suas questões juntos', () async {
      await firestore
          .collection('professores/prof1/materias')
          .doc('m1')
          .set({'nome': 'Matemática'});
      await firestore
          .collection('professores/prof1/questoes')
          .doc('q1')
          .set({
            'materiaId': 'm1',
            'enunciado': 'X',
            'alternativas': ['A', 'B'],
            'respostaCorreta': 0,
          });
      await firestore
          .collection('professores/prof1/questoes')
          .doc('q2')
          .set({
            'materiaId': 'm1',
            'enunciado': 'Y',
            'alternativas': ['A', 'B'],
            'respostaCorreta': 0,
          });
      await _aguardar(repo);

      repo.excluirMateria('m1');
      await _aguardar(repo);

      expect(
        (await firestore.doc('professores/prof1/materias/m1').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.doc('professores/prof1/questoes/q1').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.doc('professores/prof1/questoes/q2').get()).exists,
        isFalse,
      );
    });

    test('um professor não enxerga os dados de outro', () async {
      // prof1 cria dados.
      await firestore
          .collection('professores/prof1/materias')
          .doc('m1')
          .set({'nome': 'Física'});
      await _aguardar(repo);

      // prof2 tem repositório separado.
      final auth2 = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'prof2'),
      );
      final repo2 = QuestoesRepository(auth: auth2, firestore: firestore);
      await _aguardar(repo2);

      expect(repo.materias, hasLength(1));
      expect(repo2.materias, isEmpty);

      repo2.dispose();
    });

    test('logout limpa a lista', () async {
      await firestore
          .collection('professores/prof1/materias')
          .doc('m1')
          .set({'nome': 'Física'});
      await _aguardar(repo);
      expect(repo.materias, hasLength(1));

      await auth.signOut();
      await _aguardar(repo);

      expect(repo.materias, isEmpty);
      expect(repo.questoes, isEmpty);
    });

    test('mapper ignora documento inválido sem derrubar o app', () async {
      // Documento sem o campo obrigatório 'nome'.
      await firestore
          .collection('professores/prof1/materias')
          .doc('invalido')
          .set({'nomeErrado': 'X'});
      // Documento de questão corrompido.
      await firestore
          .collection('professores/prof1/questoes')
          .doc('corrompida')
          .set({'materiaId': 'm1'}); // sem enunciado/alternativas
      await _aguardar(repo);

      expect(repo.materias, isEmpty);
      expect(repo.questoes, isEmpty);
    });
  });
}
