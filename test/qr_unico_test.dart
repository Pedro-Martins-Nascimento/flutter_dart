import 'package:flutter_dart/models/prova_gerada.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/localizar_versao.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prova com [versoes] versões, cujos QRs saem do [lote].
ProvaGerada _prova(String id, String lote, {int versoes = 2, int dias = 0}) =>
    ProvaGerada(
      id: id,
      nome: 'Prova $id',
      materia: 'Mat',
      turma: '9A',
      criadoEm: DateTime(2026, 11, 20).subtract(Duration(days: dias)),
      versoes: [
        for (var n = 1; n <= versoes; n++)
          VersaoProva(
            id: 'v$n',
            qrCode: VersaoProva.qrCodeDe(lote: lote, numero: n),
            questoes: const [],
          ),
      ],
    );

void main() {
  test('o QR traz o lote e o número da versão', () {
    expect(VersaoProva.qrCodeDe(lote: 'ABC', numero: 2), 'PROVA-ABC-V2');
  });

  test('gerações em instantes diferentes têm lotes diferentes', () {
    final agora = DateTime(2026, 11, 25, 10);
    final lote1 = VersaoProva.novoLote(agora);
    final lote2 = VersaoProva.novoLote(
      agora.add(const Duration(microseconds: 1)),
    );
    expect(lote1, isNot(lote2));
    expect(lote1, matches(RegExp(r'^[0-9A-Z]+$')));
  });

  test('a Prova A de duas provas diferentes é achada na prova certa', () async {
    // A prova impressa antes da apresentação e a criada na hora.
    final repo = ProvaRepositoryMemoria();
    final antiga = _prova(
      'antiga',
      VersaoProva.novoLote(DateTime(2026, 11, 20)),
      dias: 5,
    );
    final nova = _prova('nova', VersaoProva.novoLote(DateTime(2026, 11, 25)));
    await repo.criar(antiga);
    await repo.criar(nova);

    expect(antiga.versoes.first.qrCode, isNot(nova.versoes.first.qrCode));
    final achada = await localizarVersaoPorQr(
      repo,
      antiga.versoes.first.qrCode,
    );
    expect(achada!.prova.id, 'antiga');
    expect(achada.versao.id, 'v1');
  });
}
