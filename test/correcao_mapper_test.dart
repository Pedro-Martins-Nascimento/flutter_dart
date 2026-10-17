import 'package:flutter_dart/models/correcao.dart';
import 'package:flutter_dart/services/correcao_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';

void main() {
  test('nota é a proporção de acertos de 0 a 10', () {
    expect(correcao('a').acertos, 1);
    expect(correcao('a').total, 2);
    expect(correcao('a').nota, 5);
    expect(
      correcao(
        'b',
        respostas: [resposta('q1', certa: true), resposta('q2', certa: true)],
      ).nota,
      10,
    );
  });

  test('correção sem respostas tem nota 0 em vez de dividir por zero', () {
    expect(correcao('a', respostas: const []).nota, 0);
  });

  test('ida e volta preserva todos os campos', () {
    final original = correcao('a', alunoId: 'al1', alunoNome: 'Bruno');
    final mapa = CorrecaoMapper.paraMapa(original);
    final lida = CorrecaoMapper.deMapa('a', mapa);

    expect(lida.id, 'a');
    expect(lida.provaId, 'p1');
    expect(lida.versaoId, 'v1');
    expect(lida.provaNome, 'Prova p1');
    expect(lida.materia, 'Matemática');
    expect(lida.turma, 'Turma A');
    expect(lida.alunoId, 'al1');
    expect(lida.alunoNome, 'Bruno');
    expect(lida.corrigidoEm, original.corrigidoEm);
    expect(lida.respostas.length, 2);
    expect(lida.respostas.first.questaoId, 'q1');
    expect(lida.respostas.first.correta, isTrue);
    expect(lida.respostas.last.correta, isFalse);
    expect(lida.nota, original.nota);
  });

  test('o id não vai dentro do documento', () {
    expect(CorrecaoMapper.paraMapa(correcao('a')).containsKey('id'), isFalse);
  });

  test('aluno e turma opcionais continuam nulos', () {
    final mapa = CorrecaoMapper.paraMapa(
      Correcao(
        id: 'a',
        provaId: 'p',
        versaoId: 'v',
        provaNome: 'P',
        materia: 'M',
        turma: null,
        alunoId: null,
        alunoNome: null,
        corrigidoEm: DateTime(2026),
        respostas: const [],
      ),
    );
    final lida = CorrecaoMapper.deMapa('a', mapa);
    expect(lida.turma, isNull);
    expect(lida.alunoId, isNull);
    expect(lida.alunoNome, isNull);
  });

  test('a data aceita texto ISO e Timestamp-like', () {
    final mapa = CorrecaoMapper.paraMapa(correcao('a'));
    mapa['corrigidoEm'] = '2026-05-10T00:00:00.000';
    expect(CorrecaoMapper.deMapa('a', mapa).corrigidoEm, DateTime(2026, 5, 10));

    mapa['corrigidoEm'] = _FalsoTimestamp(DateTime(2026, 1, 2));
    expect(CorrecaoMapper.deMapa('a', mapa).corrigidoEm, DateTime(2026, 1, 2));

    mapa['corrigidoEm'] = null;
    expect(() => CorrecaoMapper.deMapa('a', mapa), throwsArgumentError);
  });
}

class _FalsoTimestamp {
  _FalsoTimestamp(this._data);
  final DateTime _data;
  DateTime toDate() => _data;
}
