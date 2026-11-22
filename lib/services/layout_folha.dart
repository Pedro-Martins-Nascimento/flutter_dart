import 'dart:ui' show Offset, Rect;

/// Medidas da folha de prova, em pontos PDF (1 pt = 1/72 polegada).
///
/// É a única fonte dessas medidas: o gerador de PDF desenha com elas e o
/// leitor (OMR) usa as mesmas para saber onde procurar os marcadores de canto,
/// o QR code e as bolinhas. Mudou aqui, mudou nos dois.
class LayoutFolha {
  LayoutFolha._();

  // Página A4 (mesmos valores de PdfPageFormat.a4).
  static const double larguraPagina = 595.275590551181;
  static const double alturaPagina = 841.8897637795275;

  /// Margem padrão. O editor de layout pode trocar, por isso as funções abaixo
  /// recebem a margem em uso.
  static const double margemPadrao = 28;
  static const double margemMinima = 14;
  static const double margemMaxima = 48;

  // Marcadores de canto (quadrados pretos usados para alinhar a foto).
  static const double ladoMarcador = 16;
  static const double alturaCabecalho = 70;
  static const double alturaRodape = 24;

  // QR code da versão, no canto direito do cabeçalho do gabarito (o caderno
  // de questões não tem QR nem marcadores).
  static const double ladoQr = 48;
  static const double paddingHorizontalCabecalho = 20;

  // Bolinhas das alternativas no gabarito, com a letra dentro.
  static const double diametroBolinhaGabarito = 13;
  static const double bordaBolinha = 0.8;

  /// Os quatro marcadores de canto na página (origem no canto superior
  /// esquerdo, y para baixo): superior esquerdo, superior direito, inferior
  /// esquerdo, inferior direito.
  static List<Rect> marcadoresDeCanto({double margem = margemPadrao}) {
    final esquerda = margem;
    final direita = larguraPagina - margem - ladoMarcador;
    final topo = margem;
    final base = alturaPagina - margem - ladoMarcador;
    return [
      Rect.fromLTWH(esquerda, topo, ladoMarcador, ladoMarcador),
      Rect.fromLTWH(direita, topo, ladoMarcador, ladoMarcador),
      Rect.fromLTWH(esquerda, base, ladoMarcador, ladoMarcador),
      Rect.fromLTWH(direita, base, ladoMarcador, ladoMarcador),
    ];
  }

  /// Área do QR code na página, no mesmo sistema de coordenadas.
  static Rect areaQr({double margem = margemPadrao}) {
    final direita =
        larguraPagina - margem - paddingHorizontalCabecalho - ladoQr;
    return Rect.fromLTWH(direita, margem, ladoQr, ladoQr);
  }

  // Grade do gabarito. As bolinhas ficam em posições fixas, calculadas só a
  // partir de quantas alternativas tem cada questão, para o leitor (OMR) saber
  // onde procurar. O gabarito usa sempre a margem padrão: a margem do editor
  // de layout vale só para o caderno de questões.

  static const int colunasGabarito = 3;

  /// Distância, na horizontal, entre os centros de duas bolinhas vizinhas.
  static const double passoBolinhaGabarito = 17;

  /// Altura de uma linha da grade (bolinha de 13 pt mais o respiro).
  static const double alturaLinhaGabarito = 19;

  /// Espaço do número da questão ("01.") antes da primeira bolinha.
  static const double larguraNumeroGabarito = 22;

  /// Máximo de bolinhas numa linha; questões com mais alternativas continuam
  /// na linha de baixo.
  static const int alternativasPorLinhaGabarito = 8;

  /// Na primeira página do gabarito, a identificação do aluno e o aviso de
  /// como marcar ocupam estas alturas fixas entre o cabeçalho e a grade.
  static const double alturaIdentificacaoGabarito = 72;
  static const double alturaAvisoGabarito = 86;
  static const double espacoAntesDaGrade = 12;

  /// Topo da caixa de identificação (logo abaixo do cabeçalho).
  static const double topoIdentificacaoGabarito =
      margemPadrao + alturaCabecalho;

  /// Topo do aviso de como marcar.
  static const double topoAvisoGabarito =
      topoIdentificacaoGabarito + alturaIdentificacaoGabarito + 8;

  /// Topo da grade na primeira página e nas seguintes.
  static const double topoGradePrimeiraPagina =
      topoAvisoGabarito + alturaAvisoGabarito + espacoAntesDaGrade;
  static const double topoGradeDemaisPaginas =
      margemPadrao + alturaCabecalho + espacoAntesDaGrade;

  /// Limite de baixo da grade, acima do rodapé com os marcadores.
  static const double baseGradeGabarito =
      alturaPagina - margemPadrao - alturaRodape - 8;

  static double get larguraColunaGabarito =>
      (larguraPagina - 2 * margemPadrao) / colunasGabarito;

  static int linhasPorColunaGabarito(int pagina) =>
      ((baseGradeGabarito -
                  (pagina == 0
                      ? topoGradePrimeiraPagina
                      : topoGradeDemaisPaginas)) /
              alturaLinhaGabarito)
          .floor();

  /// Onde fica cada questão no gabarito, na ordem da prova. As questões descem
  /// pela coluna e continuam na seguinte; uma questão nunca é dividida entre
  /// colunas ou páginas.
  static List<PosicaoNoGabarito> gradeGabarito(
    List<int> alternativasPorQuestao,
  ) {
    final posicoes = <PosicaoNoGabarito>[];
    var pagina = 0, coluna = 0, linha = 0;
    for (var q = 0; q < alternativasPorQuestao.length; q++) {
      final alternativas = alternativasPorQuestao[q];
      if (alternativas < 1) {
        throw ArgumentError('A questão ${q + 1} não tem alternativas');
      }
      final linhas = (alternativas / alternativasPorLinhaGabarito).ceil();
      if (linha + linhas > linhasPorColunaGabarito(pagina)) {
        linha = 0;
        coluna++;
        if (coluna == colunasGabarito) {
          coluna = 0;
          pagina++;
        }
      }
      final topo =
          (pagina == 0 ? topoGradePrimeiraPagina : topoGradeDemaisPaginas) +
          linha * alturaLinhaGabarito;
      final esquerda =
          margemPadrao +
          paddingHorizontalCabecalho / 2 +
          coluna * larguraColunaGabarito;
      posicoes.add(
        PosicaoNoGabarito(
          pagina: pagina,
          numero: Offset(esquerda, topo),
          bolinhas: [
            for (var a = 0; a < alternativas; a++)
              Rect.fromCircle(
                center: Offset(
                  esquerda +
                      larguraNumeroGabarito +
                      (a % alternativasPorLinhaGabarito) *
                          passoBolinhaGabarito +
                      diametroBolinhaGabarito / 2,
                  topo +
                      (a ~/ alternativasPorLinhaGabarito) *
                          alturaLinhaGabarito +
                      diametroBolinhaGabarito / 2,
                ),
                radius: diametroBolinhaGabarito / 2,
              ),
          ],
        ),
      );
      linha += linhas;
    }
    return posicoes;
  }

  /// Quantas páginas tem o gabarito dessa prova.
  static int paginasDoGabarito(List<int> alternativasPorQuestao) {
    final grade = gradeGabarito(alternativasPorQuestao);
    return grade.isEmpty ? 1 : grade.last.pagina + 1;
  }
}

/// Lugar de uma questão no gabarito, em pontos da página.
class PosicaoNoGabarito {
  const PosicaoNoGabarito({
    required this.pagina,
    required this.numero,
    required this.bolinhas,
  });

  /// Página do gabarito (0 = primeira).
  final int pagina;

  /// Canto superior esquerdo do número da questão.
  final Offset numero;

  /// Uma bolinha por alternativa, na ordem impressa.
  final List<Rect> bolinhas;
}
