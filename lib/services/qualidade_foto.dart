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
  ),
  naoAnalisada(
    'Não consegui analisar a foto. Aponte a câmera para a folha de novo e capture outra vez.',
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
  static const int maximoCandidatas = 16;
}

AvaliacaoFoto avaliarFotoCodificada(Uint8List bytes) {
  try {
    final imagem = img.decodeImage(bytes);
    if (imagem == null) {
      return const AvaliacaoFoto([ProblemaFoto.naoAnalisada]);
    }
    return avaliarFoto(imagem);
  } catch (_) {
    return const AvaliacaoFoto([ProblemaFoto.naoAnalisada]);
  }
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

class _Geometria {
  _Geometria(List<_Mancha> m)
    : lados = [
        for (var i = 0; i < 4; i++)
          m[i].centro.distanceTo(m[(i + 1) % 4].centro),
      ],
      area = _areaPoligono(m.map((e) => e.centro).toList());

  final List<double> lados;
  final double area;

  double get ladoA => (lados[0] + lados[2]) / 2;
  double get ladoB => (lados[1] + lados[3]) / 2;
  double get proporcao => min(ladoA, ladoB) / max(ladoA, ladoB);
  double get larguraFolha => min(ladoA, ladoB);

  bool get simetrica =>
      min(lados[0], lados[2]) / max(lados[0], lados[2]) >=
          LimitesFoto.simetriaMinima &&
      min(lados[1], lados[3]) / max(lados[1], lados[3]) >=
          LimitesFoto.simetriaMinima;
}

double _areaPoligono(List<Point<double>> pontos) {
  var soma = 0.0;
  for (var i = 0; i < pontos.length; i++) {
    final a = pontos[i];
    final b = pontos[(i + 1) % pontos.length];
    soma += a.x * b.y - b.x * a.y;
  }
  return soma.abs() / 2;
}

double _proporcaoDaFolha(double margem) {
  final cantos = LayoutFolha.marcadoresDeCanto(margem: margem);
  final h = cantos[1].center.dx - cantos[0].center.dx;
  final v = cantos[2].center.dy - cantos[0].center.dy;
  return min(h, v) / max(h, v);
}

double _marcadorRelativo(double margem) =>
    LayoutFolha.ladoMarcador /
    (LayoutFolha.larguraPagina - 2 * margem - LayoutFolha.ladoMarcador);

final _proporcoes = [
  _proporcaoDaFolha(LayoutFolha.margemMinima),
  _proporcaoDaFolha(LayoutFolha.margemMaxima),
];
final _proporcaoMinima = _proporcoes.reduce(min);
final _proporcaoMaxima = _proporcoes.reduce(max);
final _marcadorMinimo = _marcadorRelativo(LayoutFolha.margemMinima);
final _marcadorMaximo = _marcadorRelativo(LayoutFolha.margemMaxima);

double _desvioDaProporcao(double proporcao) {
  if (proporcao < _proporcaoMinima) return _proporcaoMinima - proporcao;
  if (proporcao > _proporcaoMaxima) return proporcao - _proporcaoMaxima;
  return 0;
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

  if (soma / total < LimitesFoto.brilhoMinimo) {
    return const AvaliacaoFoto([ProblemaFoto.escura]);
  }
  final comReflexo = estourados / total > LimitesFoto.fracaoEstouradaMaxima;
  if (comReflexo) problemas.add(ProblemaFoto.reflexo);

  final marcadores = _acharMarcadores(imagem);
  if (marcadores == null) {
    int percentil(double fracao) {
      var acumulado = 0;
      for (var v = 0; v < 256; v++) {
        acumulado += histograma[v];
        if (acumulado >= total * fracao) return v;
      }
      return 255;
    }

    final apagada =
        percentil(0.99) - percentil(0.01) < LimitesFoto.contrasteMinimo * 1.5;
    if (apagada && !comReflexo) {
      return const AvaliacaoFoto([ProblemaFoto.escura]);
    }
    return AvaliacaoFoto([...problemas, ProblemaFoto.marcadores]);
  }

  final geometria = _Geometria(marcadores);
  if (!geometria.simetrica ||
      _desvioDaProporcao(geometria.proporcao) >
          LimitesFoto.toleranciaProporcao) {
    problemas.add(ProblemaFoto.inclinada);
  }
  if (geometria.area / total < LimitesFoto.areaMinimaDaFolha) {
    problemas.add(ProblemaFoto.longe);
  }

  final bordas = marcadores.map((m) => _bordas(imagem, m)).toList();
  double media(double Function(_Borda) valor) =>
      bordas.map(valor).reduce((a, b) => a + b) / bordas.length;

  if (media((b) => b.contraste) < LimitesFoto.contrasteMinimo) {
    if (!comReflexo) problemas.insert(0, ProblemaFoto.escura);
  } else if (min(media((b) => b.horizontal), media((b) => b.vertical)) <
      LimitesFoto.nitidezMinima) {
    problemas.add(ProblemaFoto.desfocada);
  }

  return AvaliacaoFoto(problemas);
}

List<_Mancha>? _acharMarcadores(_Cinza imagem) {
  final candidatas = _candidatas(imagem)
    ..sort((a, b) => b.area.compareTo(a.area));
  final topo = candidatas.take(LimitesFoto.maximoCandidatas).toList();
  if (topo.length < 4) return null;

  List<_Mancha>? melhor;
  var melhorArea = 0.0;
  final n = topo.length;
  for (var a = 0; a < n; a++) {
    for (var b = a + 1; b < n; b++) {
      for (var c = b + 1; c < n; c++) {
        for (var d = c + 1; d < n; d++) {
          final grupo = _emOrdem([topo[a], topo[b], topo[c], topo[d]]);
          if (grupo == null) continue;
          final geometria = _Geometria(grupo);
          if (geometria.area <= melhorArea) continue;
          if (_plausivel(grupo, geometria)) {
            melhor = grupo;
            melhorArea = geometria.area;
          }
        }
      }
    }
  }
  return melhor;
}

List<_Mancha>? _emOrdem(List<_Mancha> grupo) {
  final areas = grupo.map((m) => m.area);
  if (areas.reduce(max) / areas.reduce(min) > 2.5) return null;

  final cx = grupo.map((m) => m.cx).reduce((a, b) => a + b) / 4;
  final cy = grupo.map((m) => m.cy).reduce((a, b) => a + b) / 4;
  final ordenado = [...grupo]
    ..sort(
      (p, q) =>
          atan2(p.cy - cy, p.cx - cx).compareTo(atan2(q.cy - cy, q.cx - cx)),
    );

  int? sinal;
  for (var i = 0; i < 4; i++) {
    final a = ordenado[i].centro;
    final b = ordenado[(i + 1) % 4].centro;
    final c = ordenado[(i + 2) % 4].centro;
    final cruz = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if (cruz == 0) return null;
    final s = cruz.sign.toInt();
    if (sinal != null && s != sinal) return null;
    sinal = s;
  }
  return ordenado;
}

bool _plausivel(List<_Mancha> grupo, _Geometria geometria) {
  if (_desvioDaProporcao(geometria.proporcao) >
      2 * LimitesFoto.toleranciaProporcao) {
    return false;
  }
  final largura = geometria.larguraFolha;
  if (largura <= 0) return false;
  for (final m in grupo) {
    final relativo = sqrt(m.area) / largura;
    if (relativo < _marcadorMinimo * 0.4 || relativo > _marcadorMaximo * 2.5) {
      return false;
    }
  }
  return true;
}

List<_Mancha> _candidatas(_Cinza imagem) {
  final w = imagem.largura;
  final h = imagem.altura;
  final raio = max(8, max(w, h) ~/ 24);

  final integral = Int32List((w + 1) * (h + 1));
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
    final naBorda = minX <= 0 || minY <= 0 || maxX >= w - 1 || maxY >= h - 1;
    if (!naBorda &&
        mancha.largura >= 5 &&
        mancha.altura >= 5 &&
        aspecto >= 0.5 &&
        aspecto <= 2 &&
        area / (mancha.largura * mancha.altura) >= 0.6 &&
        area <= areaMaxima) {
      candidatas.add(mancha);
    }
  }
  return candidatas;
}

typedef _Borda = ({double horizontal, double vertical, double contraste});

_Borda _bordas(_Cinza imagem, _Mancha m) {
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
