import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_dart/services/correcao_repository_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';
import 'correcao_repository_contrato.dart';

void main() {
  group('CorrecaoRepositoryFirestore', () {
    testarContratoCorrecaoRepository(
      () => CorrecaoRepositoryFirestore(FakeFirebaseFirestore(), 'prof1'),
    );

    test('grava em professores/{uid}/correcoes/{id}', () async {
      final firestore = FakeFirebaseFirestore();
      await CorrecaoRepositoryFirestore(
        firestore,
        'prof1',
      ).salvar(correcao('a'));

      final doc = await firestore.doc('professores/prof1/correcoes/a').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['provaId'], 'p1');
      expect(doc.data()!.containsKey('id'), isFalse);
    });

    test('cada professor enxerga só as próprias correções', () async {
      final firestore = FakeFirebaseFirestore();
      final ana = CorrecaoRepositoryFirestore(firestore, 'ana');
      final beto = CorrecaoRepositoryFirestore(firestore, 'beto');

      await ana.salvar(correcao('a'));

      expect(await ana.listar(), hasLength(1));
      expect(await beto.listar(), isEmpty);
      expect(await beto.buscar('a'), isNull);
      expect(await beto.jaCorrigida('p1', 'v1'), isFalse);
    });
  });
}
