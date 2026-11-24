// Leitor das marcações (OMR) do gabarito (RF14).
//
// Algoritmo isolado, sem Flutter nem câmera: recebe a foto de uma página do
// gabarito e quantas alternativas tem cada questão, e devolve o quanto cada
// bolinha está marcada e qual alternativa foi escolhida. Passos:
//
// 1. Reduz a foto e passa para tons de cinza.
// 2. Binariza com limiar adaptativo (média da vizinhança), para aguentar
//    sombra e luz desigual na folha.
// 3. Acha manchas escuras quadradas e maciças: os candidatos a marcador de
//    canto. Os 4 marcadores são os candidatos mais extremos de cada canto.
// 4. Calcula a homografia (correção de perspectiva) que leva as coordenadas
//    da página, em pontos de [LayoutFolha], para a foto. Testa as 4 rotações
//    e fica com a que põe o QR code e o título do gabarito no lugar certo,
//    então a folha pode estar de lado ou de ponta-cabeça.
// 5. Mede cada bolinha da grade fixa (LayoutFolha.gradeGabarito) sem olhar o
//    centro, onde está a letra impressa, nem a borda: conta a tinta no anel
//    entre os dois e procura traços nas quatro diagonais. Uma bolinha pintada
//    enche o anel; um X preenche as quatro diagonais.
// 6. Aplica a regra de marcação (LeituraQuestao.dePreenchimento): em branco,
//    dupla ou rasurada vira "não identificada" para o professor revisar.

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect;

import 'package:image/image.dart' as img;

import 'layout_folha.dart';

enum ProblemaLeitura {
  imagemInvalida('Não consegui abrir a foto. Capture outra vez.'),
  marcadores(
    'Não encontrei os 4 marcadores de canto do gabarito. Enquadre a folha '
    'inteira e capture outra vez.',
  );

  const ProblemaLeitura(this.mensagem);

  final String mensagem;
}

class LeituraOmrException implements Exception {
  const LeituraOmrException(this.problema);

  final ProblemaLeitura problema;

  @override
  String toString() => 'LeituraOmrException: ${problema.mensagem}';
}

/// Como ficou a leitura de uma questão.
enum SituacaoQuestao {
  /// Uma alternativa marcada e nenhuma outra com tinta.
  marcada(''),

  /// Nenhuma bolinha com tinta.
  emBranco('Nenhuma alternativa marcada. Confira e selecione manualmente.'),

  /// Duas ou mais bolinhas marcadas.
  dupla('Mais de uma alternativa marcada. Confira e selecione manualmente.'),

  /// Tinta que não chega a ser uma marcação: risco, visto, rasura, ou uma
  /// bolinha marcada junto com outra rasurada.
  rasura('Marcação fraca ou rasurada. Confira e selecione manualmente.');

  const SituacaoQuestao(this.mensagem);

  /// Aviso para o professor; vazio quando a leitura é confiável.
  final String mensagem;

  /// Precisa que o professor confira e escolha na mão ("não identificada").
  bool get precisaRevisao => this != marcada;
}

/// Leitura de uma questão do gabarito.
class LeituraQuestao {
  const LeituraQuestao({
    required this.indice,
    required this.situacao,
    required this.alternativa,
    required this.preenchimento,
  });

  /// Aplica a regra de marcação a partir da nota de cada bolinha:
  ///
  /// - marcada: nota >= [LimitesOmr.limiarMarcada] (X ou bolinha pintada);
  /// - com tinta (dúvida): passa de [LimitesOmr.limiarDuvida] e fica pelo
  ///   menos [LimitesOmr.folgaSobreFundo] acima da mediana da questão (o
  ///   "fundo" daquela linha, que sobe com sombra e ruído da foto).
  ///
  /// Uma só marcada e nenhuma outra com tinta = [SituacaoQuestao.marcada].
  /// Duas ou mais marcadas = [SituacaoQuestao.dupla]. Nenhuma com tinta =
  /// [SituacaoQuestao.emBranco]. O resto = [SituacaoQuestao.rasura]. Fora de
  /// `marcada`, [alternativa] é nula e a questão vai para a revisão do
  /// professor.
  factory LeituraQuestao.dePreenchimento(
    int indice,
    List<double> preenchimento,
  ) {
    final ordenado = [...preenchimento]..sort();
    final fundo = ordenado.isEmpty ? 0.0 : ordenado[ordenado.length ~/ 2];
    final marcadas = <int>[];
    final comTinta = <int>[];
    for (var i = 0; i < preenchimento.length; i++) {
      final p = preenchimento[i];
      if (p >= LimitesOmr.limiarMarcada) {
        marcadas.add(i);
      } else if (p >= LimitesOmr.limiarDuvida &&
          p - fundo >= LimitesOmr.folgaSobreFundo) {
        comTinta.add(i);
      }
    }

    final SituacaoQuestao situacao;
    if (marcadas.length >= 2) {
      situacao = SituacaoQuestao.dupla;
    } else if (marcadas.length == 1 && comTinta.isEmpty) {
      situacao = SituacaoQuestao.marcada;
    } else if (marcadas.isEmpty && comTinta.isEmpty) {
      situacao = SituacaoQuestao.emBranco;
    } else {
      situacao = SituacaoQuestao.rasura;
    }
    return LeituraQuestao(
      indice: indice,
      situacao: situacao,
      alternativa: situacao == SituacaoQuestao.marcada ? marcadas.single : null,
      preenchimento: List.unmodifiable(preenchimento),
    );
  }

  /// Índice da questão na prova (0 = questão 1).
  final int indice;

  final SituacaoQuestao situacao;

  /// Alternativa marcada (índice na ordem impressa) quando [situacao] é
  /// `marcada`; nula nos outros casos.
  final int? alternativa;

  /// Nota (0 a 1) de cada bolinha, na ordem impressa.
  final List<double> preenchimento;
}

/// Resultado da leitura de uma página do gabarito.
class LeituraCartao {
  const LeituraCartao(this.leituras);

  /// Uma leitura por questão desta página, na ordem da prova.
  final List<LeituraQuestao> leituras;

  /// Índices (na ordem da prova, 0 = questão 1) das questões desta página.
  List<int> get questoes => [for (final l in leituras) l.indice];

  /// Quanto (0 a 1) cada bolinha está marcada, por questão desta página e por
  /// alternativa, na ordem impressa.
  List<List<double>> get preenchimento => [
    for (final l in leituras) l.preenchimento,
  ];

  /// Alternativa marcada em cada questão desta página (índice na ordem
  /// impressa), ou nulo quando a questão precisa de revisão (em branco, dupla
  /// ou rasurada).
  List<int?> get marcadas => [for (final l in leituras) l.alternativa];

  /// Índices (na ordem da prova) das questões que o professor precisa
  /// conferir.
  List<int> get paraRevisar => [
    for (final l in leituras)
      if (l.situacao.precisaRevisao) l.indice,
  ];
}

class LimitesOmr {
  LimitesOmr._();

  /// Lado maior da imagem usada na leitura, em pixels. Precisa ser grande o
  /// bastante para o traço da caneta (cerca de 0,5 pt) não sumir.
  static const int ladoLeitura = 2000;

  /// A partir de quanto a bolinha conta como marcada: um X (3 ou 4 diagonais
  /// com traço) ou 70% do anel pintado.
  static const double limiarMarcada = 0.7;

  /// A partir de quanto a bolinha tem tinta que pede revisão (um risco ou um
  /// visto, com duas diagonais, dão 0,4). Abaixo disso é ruído ou marca bem
  /// apagada: nas fotos simuladas, bolinha vazia ou apagada fica abaixo de
  /// ~0,05, mesmo com sombra forte. Ajustar com as fotos reais (tarefa 18).
  static const double limiarDuvida = 0.3;

  /// Quanto a bolinha precisa passar da mediana da própria questão para contar
  /// como tinta (e não como ruído de fundo da foto).
  static const double folgaSobreFundo = 0.1;

  /// Pixel é escuro se for mais escuro que a média da vizinhança menos isto
  /// (em fração da média).
  static const double contrasteBinarizacao = 0.25;

  /// Anel medido, em fração do raio da bolinha: fica fora da letra impressa
  /// no centro e dentro da borda.
  static const double raioInternoAnel = 0.56;
  static const double raioExternoAnel = 0.8;

  /// Uma diagonal tem traço se pelo menos esta fração dos pontos de algum
  /// raio dela (até 25° para cada lado, para aceitar X torto) for escura.
  static const double tracoNaDiagonal = 0.7;
}

class LeitorOmr {
  const LeitorOmr._();

  /// Lê uma foto codificada (JPEG, PNG...).
  static LeituraCartao lerCodificada(
    Uint8List bytes,
    List<int> alternativasPorQuestao, {
    int pagina = 0,
  }) {
    final img.Image? imagem;
    try {
      imagem = img.decodeImage(bytes);
    } catch (_) {
      throw const LeituraOmrException(ProblemaLeitura.imagemInvalida);
    }
    if (imagem == null) {
      throw const LeituraOmrException(ProblemaLeitura.imagemInvalida);
    }
    return ler(imagem, alternativasPorQuestao, pagina: pagina);
  }

  /// Lê a [pagina] (0 = primeira) do gabarito em [imagem].
  /// [alternativasPorQuestao] diz quantas bolinhas tem cada questão da prova
  /// inteira, na ordem impressa; só as questões dessa página são lidas.
  static LeituraCartao ler(
    img.Image imagem,
    List<int> alternativasPorQuestao, {
    int pagina = 0,
  }) {
    final grade = LayoutFolha.gradeGabarito(alternativasPorQuestao);
    final cinza = _Cinza.daImagem(imagem);
    final escuro = cinza.binarizar();
    final h = _localizarPagina(escuro, comQr: pagina == 0);

    final questoes = [
      for (var q = 0; q < grade.length; q++)
        if (grade[q].pagina == pagina) q,
    ];
    return LeituraCartao([
      for (final q in questoes)
        LeituraQuestao.dePreenchimento(q, [
          for (final bolinha in grade[q].bolinhas) _marca(bolinha, h, escuro),
        ]),
    ]);
  }

  /// Quanto a bolinha está marcada, de 0 a 1: o maior entre a fração do anel
  /// que está escura (bolinha pintada) e a nota das diagonais (1 com as 4
  /// diagonais com traço, um X; 0,8 com 3; 0,2 por diagonal com menos). O
  /// centro, onde está a letra impressa, não entra.
  static double _marca(Rect bolinha, Homografia h, _Binaria escuro) {
    final raio = bolinha.width / 2;
    final centro = bolinha.center;
    bool escuroEm(double angulo, double r) {
      final p = h.aplicar(
        centro + Offset(cos(angulo) * r * raio, sin(angulo) * r * raio),
      );
      return escuro.em(p.dx.round(), p.dy.round());
    }

    const raios = 7;
    double raioDoAnel(int i) =>
        LimitesOmr.raioInternoAnel +
        (LimitesOmr.raioExternoAnel - LimitesOmr.raioInternoAnel) *
            i /
            (raios - 1);

    // Anel inteiro.
    const angulosAnel = 48;
    var escurosAnel = 0;
    for (var a = 0; a < angulosAnel; a++) {
      for (var i = 0; i < raios; i++) {
        if (escuroEm(2 * pi * a / angulosAnel, raioDoAnel(i))) escurosAnel++;
      }
    }
    final anel = escurosAnel / (angulosAnel * raios);

    // Diagonais (45°, 135°, 225°, 315°), aceitando até 25° de inclinação.
    var diagonais = 0;
    for (var d = 0; d < 4; d++) {
      final base = pi / 4 + d * pi / 2;
      var melhor = 0.0;
      for (var desvio = -25; desvio <= 25; desvio += 3) {
        final angulo = base + desvio * pi / 180;
        var escuros = 0;
        for (var i = 0; i < raios; i++) {
          if (escuroEm(angulo, raioDoAnel(i))) escuros++;
        }
        melhor = max(melhor, escuros / raios);
      }
      if (melhor >= LimitesOmr.tracoNaDiagonal) diagonais++;
    }
    // Um X enche as 4 diagonais (3, se estiver torto ou apagadinho num
    // canto). Com menos, como um risco ou um visto, a nota fica baixa.
    final nota = switch (diagonais) {
      4 => 1.0,
      3 => 0.8,
      _ => diagonais * 0.2,
    };
    return max(anel, nota);
  }

  /// Homografia página -> foto, a partir dos 4 marcadores.
  static Homografia _localizarPagina(_Binaria escuro, {required bool comQr}) {
    final todos = _candidatosAMarcador(escuro);
    if (todos.length < 4) {
      throw const LeituraOmrException(ProblemaLeitura.marcadores);
    }
    // Os marcadores estão entre as maiores manchas quadradas da folha. Manchas
    // bem menores que a 4ª maior (sujeira, ruído na mesa em volta da folha)
    // saem antes de escolher os cantos.
    final areas = todos.map((m) => m.area).toList()
      ..sort((a, b) => b.compareTo(a));
    final candidatos = [
      for (final m in todos)
        if (m.area >= areas[3] * 0.35) m,
    ];

    // O mais extremo em cada direção diagonal. A ordem segue o contorno da
    // folha: superior esquerdo, superior direito, inferior direito, inferior
    // esquerdo (como aparecem na foto).
    _Mancha extremo(double Function(_Mancha m) nota) =>
        candidatos.reduce((a, b) => nota(a) >= nota(b) ? a : b);
    final cantosFoto = [
      extremo((m) => -(m.cx + m.cy)),
      extremo((m) => m.cx - m.cy),
      extremo((m) => m.cx + m.cy),
      extremo((m) => m.cy - m.cx),
    ];
    if (cantosFoto.toSet().length < 4 || !_tamanhosParecidos(cantosFoto)) {
      throw const LeituraOmrException(ProblemaLeitura.marcadores);
    }

    final m = LayoutFolha.marcadoresDeCanto();
    // Mesma ordem de contorno, na página.
    final cantosPagina = [m[0].center, m[1].center, m[3].center, m[2].center];

    // A foto pode estar girada: testa as 4 rotações e escolhe a que deixa o
    // QR code (só na primeira página) e o título do gabarito, os trechos mais
    // escuros do cabeçalho, onde eles devem estar.
    final referencias = [
      if (comQr) LayoutFolha.areaQr(),
      const Rect.fromLTWH(
        LayoutFolha.margemPadrao + LayoutFolha.ladoMarcador + 8,
        LayoutFolha.margemPadrao,
        170,
        18,
      ),
    ];
    Homografia? melhor;
    var melhorNota = double.negativeInfinity;
    for (var r = 0; r < 4; r++) {
      final destino = [
        for (var i = 0; i < 4; i++) cantosFoto[(i + r) % 4].centro,
      ];
      final h = Homografia.dePontos(cantosPagina, destino);
      if (h == null) continue;
      var nota = 0.0;
      for (final area in referencias) {
        nota += _fracaoEscura(area, h, escuro);
      }
      if (nota > melhorNota) {
        melhorNota = nota;
        melhor = h;
      }
    }
    if (melhor == null) {
      throw const LeituraOmrException(ProblemaLeitura.marcadores);
    }
    return melhor;
  }

  static double _fracaoEscura(Rect area, Homografia h, _Binaria escuro) {
    const passos = 16;
    var escuros = 0;
    for (var i = 0; i < passos; i++) {
      for (var j = 0; j < passos; j++) {
        final p = h.aplicar(
          Offset(
            area.left + (i + 0.5) / passos * area.width,
            area.top + (j + 0.5) / passos * area.height,
          ),
        );
        if (escuro.em(p.dx.round(), p.dy.round())) escuros++;
      }
    }
    return escuros / (passos * passos);
  }

  static bool _tamanhosParecidos(List<_Mancha> manchas) {
    final areas = manchas.map((m) => m.area).toList()..sort();
    return areas.first * 6 >= areas.last;
  }

  /// Manchas escuras com cara de marcador: quadradas (de lado a lado parecido),
  /// maciças, sem encostar na borda da foto e de tamanho plausível.
  static List<_Mancha> _candidatosAMarcador(_Binaria escuro) {
    final maior = max(escuro.largura, escuro.altura);
    final ladoMinimo = maior * 0.006;
    final ladoMaximo = maior * 0.1;
    return [
      for (final m in escuro.manchas())
        if (!m.encostaNaBorda(escuro.largura, escuro.altura) &&
            m.largura >= ladoMinimo &&
            m.altura >= ladoMinimo &&
            m.largura <= ladoMaximo &&
            m.altura <= ladoMaximo &&
            min(m.largura, m.altura) / max(m.largura, m.altura) >= 0.5 &&
            m.area / (m.largura * m.altura) >= 0.45 &&
            m.macica)
          m,
    ];
  }
}

class Homografia {
  Homografia._(this._h);

  /// h11..h32, com h33 = 1.
  final List<double> _h;

  /// Homografia que leva cada [origem] ao [destino] correspondente (4 pares).
  /// Nulo se os pontos forem degenerados (3 alinhados, por exemplo).
  static Homografia? dePontos(List<Offset> origem, List<Offset> destino) {
    assert(origem.length == 4 && destino.length == 4);
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final x = origem[i].dx, y = origem[i].dy;
      final u = destino[i].dx, v = destino[i].dy;
      a[2 * i].setAll(0, [x, y, 1, 0, 0, 0, -u * x, -u * y, u]);
      a[2 * i + 1].setAll(0, [0, 0, 0, x, y, 1, -v * x, -v * y, v]);
    }
    // Eliminação de Gauss com pivô parcial.
    for (var col = 0; col < 8; col++) {
      var pivo = col;
      for (var lin = col + 1; lin < 8; lin++) {
        if (a[lin][col].abs() > a[pivo][col].abs()) pivo = lin;
      }
      if (a[pivo][col].abs() < 1e-10) return null;
      final troca = a[col];
      a[col] = a[pivo];
      a[pivo] = troca;
      for (var lin = 0; lin < 8; lin++) {
        if (lin == col) continue;
        final fator = a[lin][col] / a[col][col];
        if (fator == 0) continue;
        for (var k = col; k < 9; k++) {
          a[lin][k] -= fator * a[col][k];
        }
      }
    }
    return Homografia._([for (var i = 0; i < 8; i++) a[i][8] / a[i][i]]);
  }

  Offset aplicar(Offset p) {
    final h = _h;
    final w = h[6] * p.dx + h[7] * p.dy + 1;
    return Offset(
      (h[0] * p.dx + h[1] * p.dy + h[2]) / w,
      (h[3] * p.dx + h[4] * p.dy + h[5]) / w,
    );
  }
}

class _Cinza {
  _Cinza(this.largura, this.altura, this.pixels);

  factory _Cinza.daImagem(img.Image imagem) {
    final maior = max(imagem.width, imagem.height);
    final reduzida = maior > LimitesOmr.ladoLeitura
        ? img.copyResize(
            imagem,
            width: imagem.width >= imagem.height
                ? LimitesOmr.ladoLeitura
                : null,
            height: imagem.height > imagem.width
                ? LimitesOmr.ladoLeitura
                : null,
            interpolation: img.Interpolation.average,
          )
        : imagem;
    final pixels = Uint8List(reduzida.width * reduzida.height);
    for (final p in reduzida) {
      pixels[p.y * reduzida.width + p.x] = (p.luminanceNormalized * 255)
          .round()
          .clamp(0, 255);
    }
    return _Cinza(reduzida.width, reduzida.height, pixels);
  }

  final int largura;
  final int altura;
  final Uint8List pixels;

  /// Limiar adaptativo: o pixel é escuro se estiver abaixo da média de uma
  /// janela grande ao redor (maior que o marcador, para o miolo dele não
  /// virar "claro"). Usa imagem integral para a média sair em O(1).
  _Binaria binarizar() {
    final w = largura, h = altura;
    final integral = Float64List((w + 1) * (h + 1));
    for (var y = 0; y < h; y++) {
      var linha = 0.0;
      for (var x = 0; x < w; x++) {
        linha += pixels[y * w + x];
        integral[(y + 1) * (w + 1) + x + 1] =
            integral[y * (w + 1) + x + 1] + linha;
      }
    }
    final raio = max(8, max(w, h) ~/ 12);
    final saida = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final y0 = max(0, y - raio), y1 = min(h, y + raio + 1);
      for (var x = 0; x < w; x++) {
        final x0 = max(0, x - raio), x1 = min(w, x + raio + 1);
        final soma =
            integral[y1 * (w + 1) + x1] -
            integral[y0 * (w + 1) + x1] -
            integral[y1 * (w + 1) + x0] +
            integral[y0 * (w + 1) + x0];
        final media = soma / ((x1 - x0) * (y1 - y0));
        if (pixels[y * w + x] < media * (1 - LimitesOmr.contrasteBinarizacao)) {
          saida[y * w + x] = 1;
        }
      }
    }
    return _Binaria(w, h, saida);
  }
}

class _Binaria {
  _Binaria(this.largura, this.altura, this.pixels);

  final int largura;
  final int altura;

  /// 1 = escuro.
  final Uint8List pixels;

  bool em(int x, int y) =>
      x >= 0 &&
      y >= 0 &&
      x < largura &&
      y < altura &&
      pixels[y * largura + x] == 1;

  /// Componentes conexas (vizinhança 4) de pixels escuros.
  List<_Mancha> manchas() {
    final rotulo = Int32List(largura * altura);
    final resultado = <_Mancha>[];
    final pilha = <int>[];
    var proximo = 0;
    for (var inicio = 0; inicio < pixels.length; inicio++) {
      if (pixels[inicio] != 1 || rotulo[inicio] != 0) continue;
      proximo++;
      var minX = largura, minY = altura, maxX = -1, maxY = -1, area = 0;
      var somaX = 0, somaY = 0;
      pilha.add(inicio);
      rotulo[inicio] = proximo;
      while (pilha.isNotEmpty) {
        final i = pilha.removeLast();
        final x = i % largura, y = i ~/ largura;
        area++;
        somaX += x;
        somaY += y;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        void visitar(int j) {
          if (pixels[j] == 1 && rotulo[j] == 0) {
            rotulo[j] = proximo;
            pilha.add(j);
          }
        }

        if (x > 0) visitar(i - 1);
        if (x < largura - 1) visitar(i + 1);
        if (y > 0) visitar(i - largura);
        if (y < altura - 1) visitar(i + largura);
      }
      final cx = (minX + maxX) ~/ 2, cy = (minY + maxY) ~/ 2;
      resultado.add(
        _Mancha(
          minX,
          minY,
          maxX,
          maxY,
          area,
          centroX: somaX / area,
          centroY: somaY / area,
          // Maciça: o centro pertence à própria mancha. Descarta anéis, como
          // os quadrados de posição do QR code.
          macica: rotulo[cy * largura + cx] == proximo,
        ),
      );
    }
    return resultado;
  }
}

class _Mancha {
  _Mancha(
    this.minX,
    this.minY,
    this.maxX,
    this.maxY,
    this.area, {
    required this.centroX,
    required this.centroY,
    required this.macica,
  });

  final int minX, minY, maxX, maxY, area;
  final bool macica;

  /// Centro de massa: mais fiel ao centro do marcador do que o meio da caixa
  /// quando a foto está em perspectiva.
  final double centroX, centroY;

  int get largura => maxX - minX + 1;
  int get altura => maxY - minY + 1;
  double get cx => (minX + maxX) / 2;
  double get cy => (minY + maxY) / 2;
  Offset get centro => Offset(centroX, centroY);

  bool encostaNaBorda(int w, int h) =>
      minX <= 0 || minY <= 0 || maxX >= w - 1 || maxY >= h - 1;
}
