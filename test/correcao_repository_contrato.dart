// Testes de contrato do CorrecaoRepository: rodam iguais para a versão em
// memória e para a do Firestore (fake), garantindo que se comportam igual.

import 'package:flutter_dart/services/correcao_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';

void testarContratoCorrecaoRepository(CorrecaoRepository Function() criar) {
  late CorrecaoRepository repo;

  setUp(() => repo = criar());

  test('começa vazio', () async {
    expect(await repo.listar(), isEmpty);
    expect(await repo.buscar('nao_existe'), isNull);
    expect(await repo.jaCorrigida('p1', 'v1'), isFalse);
  });

  test('salvar e buscar devolvem a correção completa', () async {
    await repo.salvar(correcao('a', alunoId: 'al1', alunoNome: 'Bruno'));

    final lida = await repo.buscar('a');
    expect(lida, isNotNull);
    expect(lida!.id, 'a');
    expect(lida.alunoNome, 'Bruno');
    expect(lida.respostas.map((r) => r.questaoId), ['q1', 'q2']);
    expect(lida.nota, 5);
    expect(lida.corrigidoEm, DateTime(2026, 5, 10));
  });

  test('salvar com id repetido falha e não altera a existente', () async {
    await repo.salvar(correcao('a', alunoNome: 'Original'));
    await expectLater(
      repo.salvar(correcao('a', alunoNome: 'Outro')),
      throwsStateError,
    );
    expect((await repo.buscar('a'))!.alunoNome, 'Original');
  });

  test('listar traz da mais nova para a mais antiga', () async {
    await repo.salvar(correcao('velha', diasAtras: 10));
    await repo.salvar(correcao('nova', diasAtras: 1));
    await repo.salvar(correcao('meio', diasAtras: 5));

    expect((await repo.listar()).map((c) => c.id), ['nova', 'meio', 'velha']);
  });

  test('jaCorrigida diferencia prova e versão', () async {
    await repo.salvar(correcao('a', provaId: 'p1', versaoId: 'v1'));

    expect(await repo.jaCorrigida('p1', 'v1'), isTrue);
    expect(await repo.jaCorrigida('p1', 'v2'), isFalse);
    expect(await repo.jaCorrigida('p2', 'v1'), isFalse);
  });

  test('excluir remove só a correção pedida', () async {
    await repo.salvar(correcao('a'));
    await repo.salvar(correcao('b', versaoId: 'v2'));

    await repo.excluir('a');

    expect(await repo.buscar('a'), isNull);
    expect(await repo.buscar('b'), isNotNull);
    expect(await repo.jaCorrigida('p1', 'v1'), isFalse);
  });

  test('excluir um id que não existe não faz nada', () async {
    await repo.salvar(correcao('a'));
    await repo.excluir('nao_existe');
    expect((await repo.listar()).length, 1);
  });

  test('observar emite o estado atual e a cada mudança', () async {
    final emitidos = <List<String>>[];
    final inscricao = repo.observar().listen(
      (lista) => emitidos.add([for (final c in lista) c.id]),
    );
    addTearDown(inscricao.cancel);

    await pumpEventQueue();
    await repo.salvar(correcao('a', diasAtras: 2));
    await pumpEventQueue();
    await repo.salvar(correcao('b', diasAtras: 1));
    await pumpEventQueue();
    await repo.excluir('a');
    await pumpEventQueue();

    expect(emitidos.first, isEmpty);
    expect(emitidos.last, ['b']);
    expect(emitidos, anyElement(orderedEquals(['b', 'a'])));
  });
}
