import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_dart/services/prova_repository_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'prova_repository_contrato.dart';

void main() {
  ProvaRepositoryFirestore repositorio(
    FakeFirebaseFirestore firestore,
    String uid,
  ) => ProvaRepositoryFirestore(uid: () => uid, firestore: firestore);

  group('ProvaRepositoryFirestore', () {
    testarContratoProvaRepository(
      () => repositorio(FakeFirebaseFirestore(), 'prof1'),
    );

    test('grava a prova e cada versão em documentos separados', () async {
      final firestore = FakeFirebaseFirestore();
      await repositorio(firestore, 'prof1').criar(prova('a', versoes: 3));

      final doc = await firestore.doc('professores/prof1/provas/a').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['totalVersoes'], 3);
      expect(doc.data()!.containsKey('id'), isFalse);
      expect(doc.data()!.containsKey('versoes'), isFalse);

      final versoes = await firestore
          .collection('professores/prof1/provas/a/versoes')
          .get();
      expect(
        versoes.docs.map((d) => d.id),
        unorderedEquals(['v1', 'v2', 'v3']),
      );
    });

    test('mantém v1, v2, ..., v10 na ordem, não na ordem do texto', () async {
      final repo = repositorio(FakeFirebaseFirestore(), 'prof1');
      await repo.criar(prova('a', versoes: 12));

      final lida = (await repo.buscar('a'))!;
      expect(lida.versoes.map((v) => v.id), [
        for (var i = 1; i <= 12; i++) 'v$i',
      ]);
    });

    test('editar apaga as versões que saíram da prova', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = repositorio(firestore, 'prof1');
      await repo.criar(prova('a', versoes: 3));
      await repo.editar(prova('a', versoes: 1));

      final versoes = await firestore
          .collection('professores/prof1/provas/a/versoes')
          .get();
      expect(versoes.docs.map((d) => d.id), ['v1']);
    });

    test('excluir apaga a prova e a subcoleção de versões', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = repositorio(firestore, 'prof1');
      await repo.criar(prova('a'));
      await repo.excluir('a');

      expect(
        (await firestore.doc('professores/prof1/provas/a').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.collection('professores/prof1/provas/a/versoes').get())
            .docs,
        isEmpty,
      );
    });

    test('cada professor enxerga só as próprias provas', () async {
      final firestore = FakeFirebaseFirestore();
      final ana = repositorio(firestore, 'ana');
      final beto = repositorio(firestore, 'beto');

      await ana.criar(prova('a'));

      expect(await ana.listar(), hasLength(1));
      expect(await beto.listar(), isEmpty);
      expect(await beto.buscar('a'), isNull);
    });
  });
}
