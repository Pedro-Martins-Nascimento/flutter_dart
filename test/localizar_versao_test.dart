import 'package:flutter_dart/services/localizar_versao.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_test/flutter_test.dart';

import 'prova_repository_contrato.dart';

void main() {
  late ProvaRepositoryMemoria repo;

  setUp(() async {
    repo = ProvaRepositoryMemoria();
    await repo.criar(prova('a'));
    await repo.criar(prova('b', diasAtras: 1));
  });

  test('acha a prova e a versão pelo QR da folha', () async {
    final achada = await localizarVersaoPorQr(repo, 'b-V2');

    expect(achada, isNotNull);
    expect(achada!.prova.id, 'b');
    expect(achada.versao.id, 'v2');
  });

  test('QR que não é de nenhuma versão devolve null', () async {
    expect(await localizarVersaoPorQr(repo, 'QR-QUALQUER'), isNull);
  });

  test('sem provas devolve null', () async {
    expect(
      await localizarVersaoPorQr(ProvaRepositoryMemoria(), 'a-V1'),
      isNull,
    );
  });
}
