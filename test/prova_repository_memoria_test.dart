import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/provas_exemplo.dart';
import 'prova_repository_contrato.dart';

void main() {
  group('ProvaRepositoryMemoria', () {
    testarContratoProvaRepository(ProvaRepositoryMemoria.new);

    test('helper criarProvaRepositoryMemoriaComMocks traz as provas de exemplo', () async {
      final comMocks = await criarProvaRepositoryMemoriaComMocks();
      final lista = await comMocks.listar();
      expect(lista, hasLength(3));
      expect(lista.first.nome, 'P1 — Matemática'); // a mais recente
      final completa = await comMocks.buscar(lista.first.id);
      expect(completa!.versoes, hasLength(4));
      expect(completa.versoes.first.questoes, isNotEmpty);
    });
  });
}
