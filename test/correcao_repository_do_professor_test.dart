import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_dart/services/correcao_repository_do_professor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';
import 'correcao_repository_contrato.dart';

void main() {
  group('CorrecaoRepositoryDoProfessor', () {
    testarContratoCorrecaoRepository(
      () => CorrecaoRepositoryDoProfessor(
        uid: () => 'prof1',
        firestore: FakeFirebaseFirestore(),
      ),
    );

    test('o uid é lido a cada chamada, não na criação', () async {
      final firestore = FakeFirebaseFirestore();
      var uid = 'ana';
      final repo = CorrecaoRepositoryDoProfessor(
        uid: () => uid,
        firestore: firestore,
      );

      await repo.salvar(correcao('a'));
      uid = 'beto';

      expect(await repo.listar(), isEmpty);
      expect(
        (await firestore.doc('professores/ana/correcoes/a').get()).exists,
        isTrue,
      );
    });
  });
}
