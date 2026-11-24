// Gera "fotos" sintéticas do gabarito para testar o leitor (OMR) sem depender
// de fotos reais: desenha a página a partir de LayoutFolha, com a letra
// impressa dentro de cada bolinha, faz as marcas pedidas e "fotografa" com
// perspectiva, rotação, sombra e ruído.

import 'dart:math';
import 'dart:ui' show Offset, Rect;

import 'package:flutter_dart/services/layout_folha.dart';
import 'package:flutter_dart/services/leitor_omr.dart';
import 'package:image/image.dart' as img;

/// Marca feita pelo aluno numa bolinha.
enum Marca {
  /// X de caneta sobre a bolinha (o jeito pedido no gabarito).
  x,

  /// X meio torto (girado uns 15°) e menor.
  xTorto,

  /// Bolinha pintada por inteiro.
  cheia,

  /// Visto (✓), que o gabarito diz para não usar.
  visto,

  /// Um risco só, na diagonal.
  risco,

  /// Pintada e depois apagada: fica um cinza bem claro.
  apagada,
}

/// Página [pagina] do gabarito em pixels, [escala] pixels por ponto.
/// [marcas] usa o índice da questão na prova inteira.
img.Image paginaGabarito(
  List<int> alternativasPorQuestao,
  Map<(int, int), Marca> marcas, {
  int pagina = 0,
  double escala = 2.5,
  int semente = 1,
}) {
  final w = (LayoutFolha.larguraPagina * escala).round();
  final h = (LayoutFolha.alturaPagina * escala).round();
  final imagem = img.Image(width: w, height: h, numChannels: 1);
  final branco = img.ColorUint8.rgb(250, 250, 250);
  img.fill(imagem, color: branco);
  final preto = img.ColorUint8.rgb(15, 15, 15);
  final caneta = img.ColorUint8.rgb(35, 45, 110);
  final cinza = img.ColorUint8.rgb(120, 120, 120);
  final apagado = img.ColorUint8.rgb(222, 222, 222);
  int px(double pt) => (pt * escala).round();

  void retangulo(Rect r, img.Color cor) => img.fillRect(
    imagem,
    x1: px(r.left),
    y1: px(r.top),
    x2: px(r.right) - 1,
    y2: px(r.bottom) - 1,
    color: cor,
  );
  void contorno(Rect r, img.Color cor) => img.drawRect(
    imagem,
    x1: px(r.left),
    y1: px(r.top),
    x2: px(r.right),
    y2: px(r.bottom),
    color: cor,
    thickness: 2,
  );
  void traco(Offset a, Offset b, img.Color cor, {double espessura = 0.8}) =>
      img.drawLine(
        imagem,
        x1: px(a.dx),
        y1: px(a.dy),
        x2: px(b.dx),
        y2: px(b.dy),
        color: cor,
        thickness: max(1, espessura * escala),
        antialias: true,
      );

  for (final m in LayoutFolha.marcadoresDeCanto()) {
    retangulo(m, preto);
  }

  // Título "GABARITO DA PROVA A" e linhas do cabeçalho, como blocos de texto.
  const x0 = LayoutFolha.margemPadrao + LayoutFolha.ladoMarcador + 10;
  for (var i = 0; i < 16; i++) {
    if (i % 5 == 4) continue; // espaço entre palavras
    retangulo(Rect.fromLTWH(x0 + i * 10, 31, 8, 11), preto);
  }
  retangulo(const Rect.fromLTWH(x0, 47, 80, 8), preto);
  retangulo(const Rect.fromLTWH(x0, 60, 14, 6), cinza);
  retangulo(const Rect.fromLTWH(x0, 70, 90, 7), cinza);

  if (pagina == 0) {
    // QR "falso": módulos aleatórios e os três quadrados de posição.
    final qr = LayoutFolha.areaQr();
    const modulos = 25;
    final lado = qr.width / modulos;
    final aleatorio = Random(semente);
    for (var i = 0; i < modulos; i++) {
      for (var j = 0; j < modulos; j++) {
        if (aleatorio.nextBool()) {
          retangulo(
            Rect.fromLTWH(qr.left + i * lado, qr.top + j * lado, lado, lado),
            preto,
          );
        }
      }
    }
    for (final (mx, my) in [(0, 0), (modulos - 7, 0), (0, modulos - 7)]) {
      final o = Offset(qr.left + mx * lado, qr.top + my * lado);
      retangulo(Rect.fromLTWH(o.dx, o.dy, 7 * lado, 7 * lado), preto);
      retangulo(
        Rect.fromLTWH(o.dx + lado, o.dy + lado, 5 * lado, 5 * lado),
        branco,
      );
      retangulo(
        Rect.fromLTWH(o.dx + 2 * lado, o.dy + 2 * lado, 3 * lado, 3 * lado),
        preto,
      );
    }

    // Caixa de identificação e aviso, com bolinhas de exemplo marcadas.
    const largura = LayoutFolha.larguraPagina - 2 * LayoutFolha.margemPadrao;
    contorno(
      const Rect.fromLTWH(
        LayoutFolha.margemPadrao,
        LayoutFolha.topoIdentificacaoGabarito,
        largura,
        60,
      ),
      cinza,
    );
    contorno(
      const Rect.fromLTWH(
        LayoutFolha.margemPadrao,
        LayoutFolha.topoAvisoGabarito,
        largura,
        70,
      ),
      img.ColorUint8.rgb(180, 83, 9),
    );
    for (var i = 0; i < 6; i++) {
      final c = Offset(
        LayoutFolha.margemPadrao + 60 + i * 17,
        LayoutFolha.topoAvisoGabarito + 50,
      );
      img.drawCircle(
        imagem,
        x: px(c.dx),
        y: px(c.dy),
        radius: px(6.5),
        color: preto,
      );
      if (i.isOdd) {
        traco(c + const Offset(-5, -5), c + const Offset(5, 5), caneta);
        traco(c + const Offset(-5, 5), c + const Offset(5, -5), caneta);
      }
    }
  }

  final grade = LayoutFolha.gradeGabarito(alternativasPorQuestao);
  for (var q = 0; q < grade.length; q++) {
    if (grade[q].pagina != pagina) continue;
    retangulo(
      Rect.fromLTWH(grade[q].numero.dx, grade[q].numero.dy + 3, 13, 7),
      preto,
    );
    for (var a = 0; a < grade[q].bolinhas.length; a++) {
      final b = grade[q].bolinhas[a];
      final c = b.center;
      final r = b.width / 2;
      // Borda (0,8 pt) e letra impressa no centro (fonte de 7 pt).
      for (var k = 0; k < 2; k++) {
        img.drawCircle(
          imagem,
          x: px(c.dx),
          y: px(c.dy),
          radius: px(r) - k,
          color: preto,
          antialias: true,
        );
      }
      traco(c + const Offset(-2, 2.5), c + const Offset(0, -2.5), preto);
      traco(c + const Offset(0, -2.5), c + const Offset(2, 2.5), preto);
      traco(c + const Offset(-1, 0.8), c + const Offset(1, 0.8), preto);

      switch (marcas[(q, a)]) {
        case Marca.x:
          traco(c + Offset(-r, -r), c + Offset(r, r), caneta);
          traco(c + Offset(-r, r), c + Offset(r, -r), caneta);
        case Marca.xTorto:
          Offset girado(double dx, double dy) {
            const t = 15 * pi / 180;
            return c +
                Offset(dx * cos(t) - dy * sin(t), dx * sin(t) + dy * cos(t));
          }
          final k = r * 0.85;
          traco(girado(-k, -k), girado(k, k), caneta);
          traco(girado(-k, k), girado(k, -k), caneta);
        case Marca.cheia:
          img.fillCircle(
            imagem,
            x: px(c.dx),
            y: px(c.dy),
            radius: px(r * 0.95),
            color: caneta,
          );
        case Marca.visto:
          traco(c + Offset(-r * 0.85, 0), c + Offset(-r * 0.15, r), caneta);
          traco(
            c + Offset(-r * 0.15, r),
            c + Offset(r * 1.1, -r * 1.1),
            caneta,
          );
        case Marca.risco:
          traco(c + Offset(-r, r), c + Offset(r, -r), caneta);
        case Marca.apagada:
          img.fillCircle(
            imagem,
            x: px(c.dx),
            y: px(c.dy),
            radius: px(r * 0.9),
            color: apagado,
          );
        case null:
      }
    }
  }
  return imagem;
}

/// "Fotografa" a [pagina]: os cantos da folha vão para [cantos] (superior
/// esquerdo, superior direito, inferior direito, inferior esquerdo da folha,
/// em pixels da foto), sobre uma mesa cinza, com [sombra] (0 a 1, escurece da
/// esquerda para a direita) e ruído.
img.Image fotografar(
  img.Image pagina, {
  required int largura,
  required int altura,
  required List<Offset> cantos,
  double sombra = 0,
  double ruido = 8,
  int semente = 2,
}) {
  final w = pagina.width.toDouble(), h = pagina.height.toDouble();
  // Da foto para a página.
  final inversa = Homografia.dePontos(cantos, [
    Offset.zero,
    Offset(w, 0),
    Offset(w, h),
    Offset(0, h),
  ])!;
  final aleatorio = Random(semente);
  final foto = img.Image(width: largura, height: altura, numChannels: 1);
  for (var y = 0; y < altura; y++) {
    for (var x = 0; x < largura; x++) {
      final p = inversa.aplicar(Offset(x.toDouble(), y.toDouble()));
      double valor;
      if (p.dx >= 0 && p.dy >= 0 && p.dx < w - 1 && p.dy < h - 1) {
        final cor = pagina.getPixelLinear(p.dx, p.dy);
        // Imagem de um canal (cinza) guarda o valor em r.
        valor = (pagina.numChannels == 1 ? cor.r : cor.luminance).toDouble();
      } else {
        valor = 90; // mesa
      }
      valor *= 1 - sombra * x / largura;
      valor += (aleatorio.nextDouble() * 2 - 1) * ruido;
      final v = valor.round().clamp(0, 255);
      foto.setPixelRgb(x, y, v, v, v);
    }
  }
  return foto;
}

/// Cantos de uma folha em pé, de frente, ocupando boa parte da foto.
List<Offset> cantosDeFrente(int largura, int altura) {
  final mx = largura * 0.07, my = altura * 0.04;
  return [
    Offset(mx, my),
    Offset(largura - mx, my),
    Offset(largura - mx, altura - my),
    Offset(mx, altura - my),
  ];
}
