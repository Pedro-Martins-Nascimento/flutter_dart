import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'layout_folha.dart';

enum ProblemaFoto {
  escura(
    'A foto está escura. Procure um lugar mais iluminado ou ligue a lanterna.',
  ),
  reflexo(
    'Tem reflexo ou luz demais na folha. Mude o ângulo do celular para tirar o brilho.',
  ),
  marcadores(
    'Não encontrei os 4 marcadores de canto. Enquadre a folha inteira, com os quadrados pretos dentro da moldura.',
  ),
  longe(
    'A folha está muito longe. Aproxime o celular até os marcadores ficarem perto da moldura.',
  ),
  inclinada(
    'A folha está torta ou inclinada. Segure o celular reto, paralelo à folha.',
  ),
  desfocada(
    'A foto está desfocada. Segure o celular firme e espere a câmera focar.',
  );

  const ProblemaFoto(this.mensagem);

  final String mensagem;
}

class AvaliacaoFoto {
  const AvaliacaoFoto(this.problemas);

  final List<ProblemaFoto> problemas;

  bool get aprovada => problemas.isEmpty;
}

class LimitesFoto {
  LimitesFoto._();

  static const int ladoAnalise = 960;
  static const double brilhoMinimo = 60;
  static const double fracaoEstouradaMaxima = 0.2;
  static const double contrasteMinimo = 40;
  static const double areaMinimaDaFolha = 0.3;
  static const double simetriaMinima = 0.8;
  static const double toleranciaProporcao = 0.12;
  static const double nitidezMinima = 0.3;
}

AvaliacaoFoto? avaliarFotoCodificada(Uint8List bytes) {
  final img.Image? imagem;
  try {
    imagem = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (imagem == null) return null;
  return avaliarFoto(imagem);
}

AvaliacaoFoto avaliarFoto(img.Image imagem) {
  final maior = max(imagem.width, imagem.height);
  final reduzida = maior > LimitesFoto.ladoAnalise
      ? img.copyResize(
          imagem,
          width: imagem.width >= imagem.height ? LimitesFoto.ladoAnalise : null,
          height: imagem.height > imagem.width ? LimitesFoto.ladoAnalise : null,
          interpolation: img.Interpolation.average,
        )
      : imagem;

  final cinza = Uint8List(reduzida.width * reduzida.height);
  for (final p in reduzida) {
    cinza[p.y * reduzida.width + p.x] = (p.luminanceNormalized * 255)
        .round()
        .clamp(0, 255);
  }
  return _avaliar(_Cinza(reduzida.width, reduzida.height, cinza));
}

class _Cinza {
  _Cinza(this.largura, this.altura, this.pixels);

  final int largura;
  final int altura;
  final Uint8List pixels;

  int at(int x, int y) => pixels[y * largura + x];
}

class _Mancha {
  _Mancha(this.minX, this.minY, this.maxX, this.maxY, this.area);

  final int minX, minY, maxX, maxY, area;

  int get largura => maxX - minX + 1;
  int get altura => maxY - minY + 1;
  double get cx => (minX + maxX) / 2;
  double get cy => (minY + maxY) / 2;
  Point<double> get centro => Point(cx, cy);
}

AvaliacaoFoto _avaliar(_Cinza imagem) {
  final problemas = <ProblemaFoto>[];
  final total = imagem.pixels.length;

  var soma = 0;
  var estourados = 0;
  final histograma = List.filled(256, 0);
  for (final p in imagem.pixels) {
    soma += p;
    histograma[p]++;
    if (p >= 250) estourados++;
  }

  int percentil(double fracao) {
    var acumulado = 0;
    for (var v = 0; v < 256; v++) {
      acumulado += histograma[v];
      if (acumulado >= total * fracao) return v;
    }
    return 255;
  }

  if (soma / total < LimitesFoto.brilhoMinimo) {
    return const AvaliacaoFoto([ProblemaFoto.escura]);
  }
  if (estourados / total > LimitesFoto.fracaoEstouradaMaxima) {
    problemas.add(ProblemaFoto.reflexo);
  } else if (percentil(0.98) - percentil(0.02) <
      LimitesFoto.contrasteMinimo * 1.5) {
    return const AvaliacaoFoto([ProblemaFoto.escura]);
  }

  final marcadores = _acharMarcadores(imagem);
  if (marcadores == null) {
    return AvaliacaoFoto([...problemas, ProblemaFoto.marcadores]);
  }

  final [se, sd, ie, id] = marcadores;
  final topo = se.centro.distanceTo(sd.centro);
  final base = ie.centro.distanceTo(id.centro);
  final esquerda = se.centro.distanceTo(ie.centro);
  final direita = sd.centro.distanceTo(id.centro);

  final cantos = LayoutFolha.marcadoresDeCanto();
  final esperadaH = cantos[1].center.dx - cantos[0].center.dx;
  final esperadaV = cantos[2].center.dy - cantos[0].center.dy;
  final proporcaoEsperada =
      min(esperadaH, esperadaV) / max(esperadaH, esperadaV);

  final horizontal = (topo + base) / 2;
  final vertical = (esquerda + direita) / 2;
  final proporcao = min(horizontal, vertical) / max(horizontal, vertical);

  if (min(topo, base) / max(topo, base) < LimitesFoto.simetriaMinima ||
      min(esquerda, direita) / max(esquerda, direita) <
          LimitesFoto.simetriaMinima ||
      (proporcao - proporcaoEsperada).abs() > LimitesFoto.toleranciaProporcao) {
    problemas.add(ProblemaFoto.inclinada);
  }

  final quadrilatero = [se.centro, sd.centro, id.centro, ie.centro];
  var area = 0.0;
  for (var i = 0; i < 4; i++) {
    final a = quadrilatero[i];
    final b = quadrilatero[(i + 1) % 4];
    area += a.x * b.y - b.x * a.y;
  }
  if (area.abs() / 2 / total < LimitesFoto.areaMinimaDaFolha) {
    problemas.add(ProblemaFoto.longe);
  }

  final bordas = marcadores.map((m) => _bordas(imagem, m)).toList();
  final contraste =
      bordas.map((b) => b.contraste).reduce((a, b) => a + b) / bordas.length;
  if (contraste < LimitesFoto.contrasteMinimo) {
    problemas.insert(0, ProblemaFoto.escura);
  } else {
    final nitidezH =
        bordas.map((b) => b.horizontal).reduce((a, b) => a + b) / bordas.length;
    final nitidezV =
        bordas.map((b) => b.vertical).reduce((a, b) => a + b) / bordas.length;
    if (min(nitidezH, nitidezV) < LimitesFoto.nitidezMinima) {
      problemas.add(ProblemaFoto.desfocada);
    }
  }

  return AvaliacaoFoto(problemas);
}

List<_Mancha>? _acharMarcadores(_Cinza imagem) {
  final w = imagem.largura;
  final h = imagem.altura;
  final raio = max(8, max(w, h) ~/ 24);

  final integral = Int64List((w + 1) * (h + 1));
  for (var y = 0; y < h; y++) {
    var linha = 0;
    for (var x = 0; x < w; x++) {
      linha += imagem.at(x, y);
      integral[(y + 1) * (w + 1) + x + 1] =
          integral[y * (w + 1) + x + 1] + linha;
    }
  }

  final escuro = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    final y0 = max(0, y - raio);
    final y1 = min(h, y + raio + 1);
    for (var x = 0; x < w; x++) {
      final x0 = max(0, x - raio);
      final x1 = min(w, x + raio + 1);
      final somaLocal =
          integral[y1 * (w + 1) + x1] -
          integral[y0 * (w + 1) + x1] -
          integral[y1 * (w + 1) + x0] +
          integral[y0 * (w + 1) + x0];
      final media = somaLocal / ((x1 - x0) * (y1 - y0));
      if (imagem.at(x, y) < media * 0.65) escuro[y * w + x] = 1;
    }
  }

  final candidatas = <_Mancha>[];
  final pilha = <int>[];
  final areaMaxima = w * h * 0.01;
  for (var inicio = 0; inicio < escuro.length; inicio++) {
    if (escuro[inicio] != 1) continue;
    escuro[inicio] = 2;
    pilha.add(inicio);
    var minX = w, minY = h, maxX = 0, maxY = 0, area = 0;
    while (pilha.isNotEmpty) {
      final i = pilha.removeLast();
      final x = i % w;
      final y = i ~/ w;
      area++;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      if (x > 0 && escuro[i - 1] == 1) {
        escuro[i - 1] = 2;
        pilha.add(i - 1);
      }
      if (x < w - 1 && escuro[i + 1] == 1) {
        escuro[i + 1] = 2;
        pilha.add(i + 1);
      }
      if (y > 0 && escuro[i - w] == 1) {
        escuro[i - w] = 2;
        pilha.add(i - w);
      }
      if (y < h - 1 && escuro[i + w] == 1) {
        escuro[i + w] = 2;
        pilha.add(i + w);
      }
    }
    final mancha = _Mancha(minX, minY, maxX, maxY, area);
    final aspecto = mancha.largura / mancha.altura;
    if (mancha.largura >= 5 &&
        mancha.altura >= 5 &&
        aspecto >= 0.5 &&
        aspecto <= 2 &&
        area / (mancha.largura * mancha.altura) >= 0.7 &&
        area <= areaMaxima) {
      candidatas.add(mancha);
    }
  }
  if (candidatas.length < 4) return null;

  _Mancha extremo(double Function(_Mancha) chave) =>
      candidatas.reduce((a, b) => chave(a) <= chave(b) ? a : b);

  final se = extremo((m) => m.cx + m.cy);
  final id = extremo((m) => -(m.cx + m.cy));
  final sd = extremo((m) => -(m.cx - m.cy));
  final ie = extremo((m) => m.cx - m.cy);
  final marcadores = [se, sd, ie, id];
  if (marcadores.toSet().length < 4) return null;

  for (final m in marcadores) {
    if (m.minX <= 0 || m.minY <= 0 || m.maxX >= w - 1 || m.maxY >= h - 1) {
      return null;
    }
  }

  final areas = marcadores.map((m) => m.area);
  if (areas.reduce(max) / areas.reduce(min) > 3) return null;

  final larguraFolha = min(
    (se.centro.distanceTo(sd.centro) + ie.centro.distanceTo(id.centro)) / 2,
    (se.centro.distanceTo(ie.centro) + sd.centro.distanceTo(id.centro)) / 2,
  );
  if (larguraFolha <= 0) return null;
  final esperado =
      LayoutFolha.ladoMarcador /
      (LayoutFolha.larguraPagina -
          2 * LayoutFolha.margemPadrao -
          LayoutFolha.ladoMarcador);
  for (final m in marcadores) {
    final relativo = sqrt(m.area) / larguraFolha;
    if (relativo < esperado * 0.4 || relativo > esperado * 2.5) return null;
  }

  return marcadores;
}

({double horizontal, double vertical, double contraste}) _bordas(
  _Cinza imagem,
  _Mancha m,
) {
  final alcance = max(3, max(m.largura, m.altura) ~/ 2);
  final cy = m.cy.round();
  final cx = m.cx.round();

  ({double nitidez, double contraste}) linha(int x0, int y0, int dx, int dy) {
    var maiorSalto = 0;
    var claro = 0;
    var escuro = 255;
    for (var k = 0; k <= 2 * alcance; k++) {
      final x = x0 + dx * k;
      final y = y0 + dy * k;
      if (x < 0 || y < 0 || x >= imagem.largura || y >= imagem.altura) continue;
      final v = imagem.at(x, y);
      claro = max(claro, v);
      escuro = min(escuro, v);
      final xn = x + dx;
      final yn = y + dy;
      if (k < 2 * alcance &&
          xn >= 0 &&
          yn >= 0 &&
          xn < imagem.largura &&
          yn < imagem.altura) {
        maiorSalto = max(maiorSalto, (imagem.at(xn, yn) - v).abs());
      }
    }
    final contraste = (claro - escuro).toDouble();
    return (
      nitidez: contraste == 0 ? 0 : maiorSalto / contraste,
      contraste: contraste,
    );
  }

  final esquerda = linha(m.minX - alcance, cy, 1, 0);
  final direita = linha(m.maxX - alcance, cy, 1, 0);
  final cima = linha(cx, m.minY - alcance, 0, 1);
  final baixo = linha(cx, m.maxY - alcance, 0, 1);

  return (
    horizontal: (esquerda.nitidez + direita.nitidez) / 2,
    vertical: (cima.nitidez + baixo.nitidez) / 2,
    contraste:
        (esquerda.contraste +
            direita.contraste +
            cima.contraste +
            baixo.contraste) /
        4,
  );
}
