// Validação do leitor (OMR) com o gabarito real gerado pelo app e com as
// fotos de gabaritos reais em test/omr_amostras/fotos (quando houver).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_dart/services/layout_folha.dart';
import 'package:flutter_dart/services/leitor_omr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'helpers/foto_cartao.dart';

void main() {
  test('lê o gabarito gerado pelo PDF, marcado com X e fotografado torto', () {
    final gabarito = img.decodePng(
      File('test/omr_amostras/gabarito_40_questoes.png').readAsBytesSync(),
    )!;
    final alternativas = [for (var i = 0; i < 40; i++) i % 7 == 0 ? 4 : 5];
    // Respostas variadas e duas questões em branco.
    final marcadas = <int?>[
      for (var i = 0; i < 40; i++) (i * 2 + i ~/ 5) % alternativas[i],
    ];
    marcadas[5] = null;
    marcadas[33] = null;

    final escala = gabarito.width / LayoutFolha.larguraPagina;
    final caneta = img.ColorRgb8(30, 40, 110);
    final grade = LayoutFolha.gradeGabarito(alternativas);
    for (var q = 0; q < 40; q++) {
      final a = marcadas[q];
      if (a == null) continue;
      final b = grade[q].bolinhas[a];
      final r = b.width / 2;
      for (final (dx, dy) in [(1.0, 1.0), (1.0, -1.0)]) {
        img.drawLine(
          gabarito,
          x1: ((b.center.dx - r * dx) * escala).round(),
          y1: ((b.center.dy - r * dy) * escala).round(),
          x2: ((b.center.dx + r * dx) * escala).round(),
          y2: ((b.center.dy + r * dy) * escala).round(),
          color: caneta,
          thickness: 2,
        );
      }
    }

    final foto = fotografar(
      gabarito,
      largura: 1500,
      altura: 1900,
      cantos: const [
        Offset(170, 140),
        Offset(1360, 70),
        Offset(1430, 1830),
        Offset(100, 1760),
      ],
      sombra: 0.35,
      ruido: 10,
    );
    expect(LeitorOmr.ler(foto, alternativas).marcadas, marcadas);
  });

  final pasta = Directory('test/omr_amostras/fotos');
  final fotos = pasta.existsSync()
      ? (pasta
            .listSync()
            .whereType<File>()
            .where(
              (f) => RegExp(
                r'\.(jpe?g|png)$',
                caseSensitive: false,
              ).hasMatch(f.path),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  test(
    'taxa de acerto com fotos reais',
    () {
      var certas = 0;
      var total = 0;
      final falhas = <String>[];
      for (final foto in fotos) {
        final nome = foto.uri.pathSegments.last;
        final esperado = jsonDecode(
          File(foto.path.replaceFirst(RegExp(r'\.\w+$'), '.json'))
              .readAsStringSync(),
        ) as Map<String, dynamic>;
        final alternativas = List<int>.from(esperado['alternativas'] as List);
        final marcadas = List<int?>.from(esperado['marcadas'] as List);
        final pagina = esperado['pagina'] as int? ?? 0;
        try {
          final lidas = LeitorOmr.lerCodificada(
            foto.readAsBytesSync(),
            alternativas,
            pagina: pagina,
          ).marcadas;
          for (var q = 0; q < marcadas.length; q++) {
            total++;
            final lida = q < lidas.length ? lidas[q] : null;
            if (lida == marcadas[q]) {
              certas++;
            } else {
              falhas.add(
                '$nome Q${q + 1}: lida $lida, esperada ${marcadas[q]}',
              );
            }
          }
        } on LeituraOmrException catch (e) {
          total += marcadas.length;
          falhas.add('$nome: ${e.problema.name}');
        }
      }
      final taxa = total == 0 ? 0 : certas / total * 100;
      // ignore: avoid_print
      print(
        'OMR: $certas de $total alternativas lidas certo '
        '(${taxa.toStringAsFixed(1)}%)\n${falhas.join('\n')}',
      );
    },
    skip: fotos.isEmpty
        ? 'Sem fotos reais em test/omr_amostras/fotos (tarefa 3)'
        : false,
  );
}
