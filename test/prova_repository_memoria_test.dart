import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_dart/services/provas_repository.dart';
import 'package:flutter_test/flutter_test.dart';

ProvaGerada prova(String id, {int diasAtras = 0, int versoes = 2}) {
  final questao = Questao(
    id: 'q1',
    materiaId: 'mat1',
    enunciado: 'Quanto é 7 x 8?',
    alternativas: ['54', '56', '58', '64'],
    respostaCorreta: 1,
  );
  return ProvaGerada(
    id: id,
    nome: 'Prova $id',
    materia: 'Matemática',
    turma: 'Turma A',
    criadoEm: DateTime(2026, 5, 10).subtract(Duration(days: diasAtras)),
    versoes: [
      for (var i = 1; i <= versoes; i++)
        VersaoProva(
          id: 'v$i',
          qrCode: '$id-V$i',
          questoes: [
            QuestaoNaVersao(
              questao: questao,
              alternativas: ['64', '56', '54', '58'],
              respostaCorreta: 1,
            ),
          ],
        ),
    ],
  );
}

void main() {
  late ProvaRepositoryMemoria repo;

  setUp(() => repo = ProvaRepositoryMemoria());

  test('começa vazio', () async {
    expect(await repo.listar(), isEmpty);
    expect(await repo.buscar('nao_existe'), isNull);
  });

  test('criar e buscar devolvem a prova completa', () async {
    await repo.criar(prova('a'));
    final lida = await repo.buscar('a');
    expect(lida, isNotNull);
    expect(lida!.nome, 'Prova a');
    expect(lida.versoes.map((v) => v.id), ['v1', 'v2']);
    expect(lida.versoes.first.questoes.first.respostaCorreta, 1);
    expect(lida.versoes.first.questoes.first.alternativas.first, '64');
  });

  test('criar com id repetido falha', () async {
    await repo.criar(prova('a'));
    await expectLater(repo.criar(prova('a')), throwsStateError);
  });

  test(
    'listar traz resumos, mais nova primeiro, com total de versões',
    () async {
      await repo.criar(prova('velha', diasAtras: 10, versoes: 3));
      await repo.criar(prova('nova', diasAtras: 1, versoes: 1));
      await repo.criar(prova('meio', diasAtras: 5));
      final lista = await repo.listar();
      expect(lista.map((p) => p.id), ['nova', 'meio', 'velha']);
      expect(lista.last.totalVersoes, 3);
      expect(lista.first.turma, 'Turma A');
    },
  );

  test(
    'o objeto lido é uma cópia: mudar nele não altera o repositório',
    () async {
      await repo.criar(prova('a'));
      final lida = (await repo.buscar('a'))!;
      lida.versoes.first.alunoId = 'al1';
      expect((await repo.buscar('a'))!.versoes.first.alunoId, isNull);
    },
  );

  test('atualizarVersao muda só a versão indicada', () async {
    await repo.criar(prova('a'));
    final lida = (await repo.buscar('a'))!;
    lida.versoes[1].alunoId = 'al2';
    await repo.atualizarVersao('a', lida.versoes[1]);

    final depois = (await repo.buscar('a'))!;
    expect(depois.versoes[0].alunoId, isNull);
    expect(depois.versoes[1].alunoId, 'al2');
  });

  test('atualizarVersao com prova ou versão inexistente falha', () async {
    await repo.criar(prova('a'));
    final v = (await repo.buscar('a'))!.versoes.first;
    await expectLater(repo.atualizarVersao('x', v), throwsStateError);
    final fantasma = prova('a', versoes: 5).versoes.last; // v5
    await expectLater(repo.atualizarVersao('a', fantasma), throwsStateError);
  });

  test('editar troca campos e versões', () async {
    await repo.criar(prova('a', versoes: 3));
    await repo.editar(
      ProvaGerada(
        id: 'a',
        nome: 'Nome novo',
        materia: 'Matemática',
        turma: null,
        criadoEm: DateTime(2026, 5, 10),
        versoes: prova('a', versoes: 1).versoes,
      ),
    );
    final lida = (await repo.buscar('a'))!;
    expect(lida.nome, 'Nome novo');
    expect(lida.turma, isNull);
    expect(lida.versoes, hasLength(1));
    expect((await repo.listar()).single.totalVersoes, 1);
  });

  test('editar prova inexistente falha', () async {
    await expectLater(repo.editar(prova('x')), throwsStateError);
  });

  test('excluir remove a prova; excluir de novo não faz nada', () async {
    await repo.criar(prova('a'));
    await repo.criar(prova('b'));
    await repo.excluir('a');
    expect((await repo.listar()).map((p) => p.id), ['b']);
    expect(await repo.buscar('a'), isNull);
    await repo.excluir('a');
    expect(await repo.listar(), hasLength(1));
  });

  test('observar emite a lista atual e depois cada mudança', () async {
    await repo.criar(prova('a'));
    final emissoes = <List<String>>[];
    final sub = repo.observar().listen(
      (lista) => emissoes.add([for (final p in lista) p.id]),
    );
    await Future<void>.delayed(Duration.zero);

    await repo.criar(prova('b', diasAtras: 1));
    await repo.excluir('a');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(emissoes, [
      ['a'],
      ['a', 'b'],
      ['b'],
    ]);
  });

  test('comMocks já traz as provas de exemplo', () async {
    final comMocks = ProvaRepositoryMemoria.comMocks();
    final lista = await comMocks.listar();
    expect(lista, hasLength(3));
    expect(lista.first.nome, 'P1 — Matemática'); // a mais recente
    final completa = await comMocks.buscar(lista.first.id);
    expect(completa!.versoes, hasLength(4));
    expect(completa.versoes.first.questoes, isNotEmpty);
  });
}
