import 'dart:typed_data';

import 'package:flutter_dart/services/layout_folha.dart';
import 'package:flutter_dart/services/leitor_omr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'helpers/foto_cartao.dart';

void main() {
  // 40 questões, como uma prova grande: a cada 7, uma tem 4 alternativas.
  final alternativas = [for (var i = 0; i < 40; i++) i % 7 == 0 ? 4 : 5];
  final gabarito = [for (var i = 0; i < 40; i++) (i * 3) % alternativas[i]];
  final marcasX = {for (var i = 0; i < 40; i++) (i, gabarito[i]): Marca.x};
  final pagina = paginaGabarito(alternativas, marcasX);

  img.Image deFrente(img.Image p) => fotografar(
    p,
    largura: 1500,
    altura: 2000,
    cantos: cantosDeFrente(1500, 2000),
  );

  group('Homografia', () {
    test('leva os 4 pontos de origem aos de destino', () {
      const origem = [
        Offset(0, 0),
        Offset(10, 0),
        Offset(10, 20),
        Offset(0, 20),
      ];
      const destino = [
        Offset(5, 7),
        Offset(40, 2),
        Offset(45, 60),
        Offset(2, 55),
      ];
      final h = Homografia.dePontos(origem, destino)!;
      for (var i = 0; i < 4; i++) {
        final p = h.aplicar(origem[i]);
        expect(p.dx, closeTo(destino[i].dx, 1e-6));
        expect(p.dy, closeTo(destino[i].dy, 1e-6));
      }
    });

    test('pontos alinhados não têm homografia', () {
      const alinhados = [
        Offset(0, 0),
        Offset(1, 1),
        Offset(2, 2),
        Offset(3, 3),
      ];
      expect(Homografia.dePontos(alinhados, alinhados), isNull);
    });
  });

  group('LeitorOmr', () {
    test('lê o X de cada questão com a folha de frente', () {
      final leitura = LeitorOmr.ler(deFrente(pagina), alternativas);
      expect(leitura.questoes, List.generate(40, (i) => i));
      expect(leitura.marcadas, gabarito);
    });

    test('lê bolinha pintada e X torto do mesmo jeito', () {
      final marcas = {
        for (var i = 0; i < 40; i++)
          (i, gabarito[i]): i.isEven ? Marca.cheia : Marca.xTorto,
      };
      final leitura = LeitorOmr.ler(
        deFrente(paginaGabarito(alternativas, marcas)),
        alternativas,
      );
      expect(leitura.marcadas, gabarito);
    });

    test('folha inclinada (perspectiva), com sombra e ruído', () {
      final foto = fotografar(
        pagina,
        largura: 1500,
        altura: 2000,
        cantos: const [
          Offset(200, 120),
          Offset(1380, 190),
          Offset(1450, 1930),
          Offset(90, 1850),
        ],
        sombra: 0.45,
        ruido: 14,
      );
      expect(LeitorOmr.ler(foto, alternativas).marcadas, gabarito);
    });

    test('sombra forte (60%) com a mesa escura em volta da folha', () {
      final foto = fotografar(
        pagina,
        largura: 1500,
        altura: 2000,
        cantos: const [
          Offset(200, 120),
          Offset(1380, 190),
          Offset(1450, 1930),
          Offset(90, 1850),
        ],
        sombra: 0.6,
        ruido: 16,
      );
      expect(LeitorOmr.ler(foto, alternativas).marcadas, gabarito);
    });

    test('folha de ponta-cabeça', () {
      final c = cantosDeFrente(1500, 2000);
      final foto = fotografar(
        pagina,
        largura: 1500,
        altura: 2000,
        cantos: [c[2], c[3], c[0], c[1]],
      );
      expect(LeitorOmr.ler(foto, alternativas).marcadas, gabarito);
    });

    test('folha deitada (foto na horizontal)', () {
      final foto = fotografar(
        pagina,
        largura: 2000,
        altura: 1500,
        cantos: const [
          Offset(1890, 90),
          Offset(1890, 1410),
          Offset(110, 1410),
          Offset(110, 90),
        ],
      );
      expect(LeitorOmr.ler(foto, alternativas).marcadas, gabarito);
    });

    test('foto maior que o limite é reduzida e lida igual', () {
      final foto = fotografar(
        pagina,
        largura: 2400,
        altura: 3200,
        cantos: cantosDeFrente(2400, 3200),
      );
      expect(LeitorOmr.ler(foto, alternativas).marcadas, gabarito);
    });

    test('letra impressa e borda não contam como marca', () {
      final leitura = LeitorOmr.ler(deFrente(pagina), alternativas);
      for (var q = 0; q < 40; q++) {
        for (var a = 0; a < alternativas[q]; a++) {
          final p = leitura.preenchimento[q][a];
          final nome = 'Q${q + 1} ${'ABCDE'[a]}';
          if (a == gabarito[q]) {
            expect(p, greaterThanOrEqualTo(0.8), reason: nome);
          } else {
            expect(p, lessThan(0.2), reason: nome);
          }
        }
      }
    });

    test('visto e risco solto não passam por X', () {
      final marcas = {
        (0, 1): Marca.visto,
        (1, 2): Marca.risco,
        (2, 3): Marca.apagada,
      };
      final leitura = LeitorOmr.ler(
        deFrente(paginaGabarito(alternativas, marcas)),
        alternativas,
      );
      expect(leitura.marcadas.take(3), [null, null, null]);
      expect(leitura.preenchimento[0][1], lessThan(LimitesOmr.limiarMarcada));
      expect(leitura.preenchimento[1][2], lessThan(LimitesOmr.limiarMarcada));
      expect(leitura.preenchimento[2][3], lessThan(0.2));
    });

    test('lê a segunda página do gabarito, que não tem QR', () {
      // 100 questões: a 5ª tem 12 alternativas (duas linhas).
      final muitas = [for (var i = 0; i < 100; i++) i == 4 ? 12 : 5];
      final grade = LayoutFolha.gradeGabarito(muitas);
      final daSegunda = [
        for (var q = 0; q < 100; q++)
          if (grade[q].pagina == 1) q,
      ];
      expect(daSegunda, isNotEmpty);
      final marcas = {for (final q in daSegunda) (q, q % 5): Marca.x};
      final foto = deFrente(paginaGabarito(muitas, marcas, pagina: 1));

      final leitura = LeitorOmr.ler(foto, muitas, pagina: 1);
      expect(leitura.questoes, daSegunda);
      expect(leitura.marcadas, [for (final q in daSegunda) q % 5]);
    });

    test('questão com 12 alternativas: lê a que está na segunda linha', () {
      final muitas = [5, 12, 5];
      final foto = deFrente(
        paginaGabarito(muitas, {(0, 0): Marca.x, (1, 10): Marca.x}),
      );
      expect(LeitorOmr.ler(foto, muitas).marcadas, [0, 10, null]);
    });

    test('lê também a imagem codificada em PNG', () {
      final png = Uint8List.fromList(img.encodePng(deFrente(pagina)));
      expect(LeitorOmr.lerCodificada(png, alternativas).marcadas, gabarito);
    });

    test('foto sem os marcadores avisa', () {
      final branca = img.Image(width: 600, height: 800, numChannels: 1);
      img.fill(branca, color: img.ColorUint8.rgb(240, 240, 240));
      expect(
        () => LeitorOmr.ler(branca, alternativas),
        throwsA(
          isA<LeituraOmrException>().having(
            (e) => e.problema,
            'problema',
            ProblemaLeitura.marcadores,
          ),
        ),
      );
    });

    test('bytes que não são imagem avisam', () {
      expect(
        () => LeitorOmr.lerCodificada(Uint8List.fromList([1, 2, 3]), [4]),
        throwsA(
          isA<LeituraOmrException>().having(
            (e) => e.problema,
            'problema',
            ProblemaLeitura.imagemInvalida,
          ),
        ),
      );
    });
  });

  group('grade do gabarito', () {
    test('bolinhas não se sobrepõem nem saem da área entre os marcadores', () {
      final muitas = [for (var i = 0; i < 200; i++) i % 9 == 0 ? 8 : 5];
      final grade = LayoutFolha.gradeGabarito(muitas);
      final m = LayoutFolha.marcadoresDeCanto();
      for (var p = 0; p <= grade.last.pagina; p++) {
        final daPagina = [
          for (final q in grade)
            if (q.pagina == p) ...q.bolinhas,
        ];
        for (var i = 0; i < daPagina.length; i++) {
          final b = daPagina[i];
          expect(b.top, greaterThan(m[0].bottom + 40));
          expect(b.bottom, lessThan(m[2].top));
          expect(b.left, greaterThan(m[0].left));
          expect(b.right, lessThan(m[1].right));
          for (var j = i + 1; j < daPagina.length; j++) {
            expect(b.overlaps(daPagina[j]), isFalse);
          }
        }
      }
    });

    test('na primeira página a grade fica abaixo do aviso', () {
      final grade = LayoutFolha.gradeGabarito([5, 5]);
      expect(
        grade.first.bolinhas.first.top,
        greaterThanOrEqualTo(
          LayoutFolha.topoAvisoGabarito + LayoutFolha.alturaAvisoGabarito,
        ),
      );
    });

    test('questão com mais de 8 alternativas ocupa duas linhas', () {
      final grade = LayoutFolha.gradeGabarito([12, 5]);
      final bolinhas = grade[0].bolinhas;
      expect(bolinhas[8].center.dy, greaterThan(bolinhas[7].center.dy));
      expect(bolinhas[8].center.dx, bolinhas[0].center.dx);
      expect(
        grade[1].numero.dy - grade[0].numero.dy,
        2 * LayoutFolha.alturaLinhaGabarito,
      );
    });

    test('questão nunca é dividida entre colunas', () {
      final linhas = LayoutFolha.linhasPorColunaGabarito(0);
      // Enche a coluna menos uma linha e põe uma questão de duas linhas.
      final alternativas = [...List.filled(linhas - 1, 5), 12];
      final grade = LayoutFolha.gradeGabarito(alternativas);
      final ultima = grade.last;
      expect(ultima.numero.dx, greaterThan(grade.first.numero.dx));
      expect(
        ultima.bolinhas.last.center.dx,
        greaterThan(grade.first.numero.dx),
      );
    });

    test('muitas questões continuam nas páginas seguintes', () {
      expect(LayoutFolha.paginasDoGabarito([5, 5]), 1);
      expect(LayoutFolha.paginasDoGabarito(List.filled(130, 5)), 2);
      expect(LayoutFolha.paginasDoGabarito(const []), 1);
    });

    test('questão sem alternativas é erro', () {
      expect(() => LayoutFolha.gradeGabarito([5, 0]), throwsArgumentError);
    });
  });
}
