import 'dart:typed_data';

import 'package:flutter_dart/services/layout_folha.dart';
import 'package:flutter_dart/services/qualidade_foto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

img.Image folha({
  int largura = 760,
  int altura = 1000,
  double escala = 1.2,
  int fundo = 90,
  int papel = 225,
  int tinta = 25,
  double margem = LayoutFolha.margemPadrao,
  bool semMarcadorInferiorDireito = false,
}) {
  final imagem = img.Image(width: largura, height: altura);
  img.fill(imagem, color: img.ColorRgb8(fundo, fundo, fundo));

  final lp = LayoutFolha.larguraPagina * escala;
  final ap = LayoutFolha.alturaPagina * escala;
  final ox = ((largura - lp) / 2).round();
  final oy = ((altura - ap) / 2).round();

  img.fillRect(
    imagem,
    x1: ox,
    y1: oy,
    x2: ox + lp.round(),
    y2: oy + ap.round(),
    color: img.ColorRgb8(papel, papel, papel),
  );

  final cantos = LayoutFolha.marcadoresDeCanto(margem: margem);
  for (var i = 0; i < cantos.length; i++) {
    if (semMarcadorInferiorDireito && i == 3) continue;
    final r = cantos[i];
    img.fillRect(
      imagem,
      x1: ox + (r.left * escala).round(),
      y1: oy + (r.top * escala).round(),
      x2: ox + (r.right * escala).round(),
      y2: oy + (r.bottom * escala).round(),
      color: img.ColorRgb8(tinta, tinta, tinta),
    );
  }

  for (var linha = 0; linha < 20; linha++) {
    final y = oy + ((140 + linha * 30) * escala).round();
    for (var b = 0; b < 4; b++) {
      img.drawCircle(
        imagem,
        x: ox + ((80 + b * 40) * escala).round(),
        y: y,
        radius: (5 * escala).round(),
        color: img.ColorRgb8(tinta, tinta, tinta),
      );
    }
  }
  return imagem;
}

void main() {
  test('folha nítida, clara e enquadrada é aprovada', () {
    final avaliacao = avaliarFoto(folha());
    expect(avaliacao.problemas, isEmpty);
    expect(avaliacao.aprovada, isTrue);
  });

  test('folha girada 90° também é aprovada', () {
    expect(avaliarFoto(img.copyRotate(folha(), angle: 90)).aprovada, isTrue);
  });

  test('imagem grande é reduzida e aprovada', () {
    final grande = img.copyResize(folha(), width: 1900);
    expect(avaliarFoto(grande).aprovada, isTrue);
  });

  test('foto escura pede nova foto', () {
    final escura = folha(fundo: 10, papel: 40, tinta: 5);
    expect(avaliarFoto(escura).problemas, [ProblemaFoto.escura]);
  });

  test('foto com pouco contraste conta como escura', () {
    final apagada = folha(fundo: 70, papel: 95, tinta: 70);
    expect(avaliarFoto(apagada).problemas, contains(ProblemaFoto.escura));
  });

  test('reflexo forte na folha pede nova foto', () {
    final brilho = folha(papel: 255, fundo: 255);
    expect(avaliarFoto(brilho).problemas, contains(ProblemaFoto.reflexo));
  });

  test('foto desfocada pede nova foto', () {
    final borrada = img.gaussianBlur(folha(), radius: 8);
    expect(avaliarFoto(borrada).problemas, contains(ProblemaFoto.desfocada));
  });

  test('marcador fora do enquadramento pede nova foto', () {
    final cortada = img.copyCrop(folha(), x: 0, y: 0, width: 700, height: 940);
    expect(avaliarFoto(cortada).problemas, contains(ProblemaFoto.marcadores));
  });

  test('marcador faltando pede nova foto', () {
    final semCanto = folha(semMarcadorInferiorDireito: true);
    expect(avaliarFoto(semCanto).problemas, contains(ProblemaFoto.marcadores));
  });

  test('folha muito longe pede nova foto', () {
    final longe = folha(largura: 1400, altura: 1800, escala: 0.9);
    expect(avaliarFoto(longe).problemas, contains(ProblemaFoto.longe));
  });

  test('folha esticada na diagonal conta como inclinada', () {
    final esticada = img.copyResize(folha(), width: 1300, height: 1000);
    expect(avaliarFoto(esticada).problemas, contains(ProblemaFoto.inclinada));
  });

  test('JPEG da câmera é decodificado e avaliado', () {
    expect(avaliarFotoCodificada(img.encodeJpg(folha())).aprovada, isTrue);
  });

  test('folha ocupando a foto inteira, sem fundo escuro, é aprovada', () {
    final cheia = folha(largura: 720, altura: 1020, escala: 1.2, fundo: 225);
    expect(avaliarFoto(cheia).problemas, isEmpty);
  });

  test('folhas com margem mínima e máxima do editor são aprovadas', () {
    expect(
      avaliarFoto(folha(margem: LayoutFolha.margemMinima)).problemas,
      isEmpty,
    );
    expect(
      avaliarFoto(folha(margem: LayoutFolha.margemMaxima)).problemas,
      isEmpty,
    );
  });

  test('objetos escuros fora da folha não atrapalham os marcadores', () {
    final mesa = folha(largura: 900, altura: 1150);
    final preto = img.ColorRgb8(10, 10, 10);
    img.fillRect(mesa, x1: 8, y1: 8, x2: 30, y2: 30, color: preto);
    img.fillRect(mesa, x1: 860, y1: 1110, x2: 885, y2: 1135, color: preto);
    img.fillCircle(mesa, x: 120, y: 160, radius: 7, color: preto);
    expect(avaliarFoto(mesa).problemas, isEmpty);
  });

  test('folha girada um pouco no plano é aprovada', () {
    final girada = img.copyRotate(
      folha(largura: 900, altura: 1150),
      angle: 12,
      interpolation: img.Interpolation.linear,
    );
    expect(avaliarFoto(girada).problemas, isEmpty);
  });

  test('reflexo não vem junto com aviso de foto escura', () {
    final lavada = folha(papel: 255, fundo: 255, tinta: 225);
    final problemas = avaliarFoto(lavada).problemas;
    expect(problemas, contains(ProblemaFoto.reflexo));
    expect(problemas, isNot(contains(ProblemaFoto.escura)));
  });

  test('bytes que não são imagem não são avaliados', () {
    expect(avaliarFotoCodificada(Uint8List.fromList([1, 2, 3])).problemas, [
      ProblemaFoto.naoAnalisada,
    ]);
  });
}
