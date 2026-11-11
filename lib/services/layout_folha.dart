import 'dart:ui' show Rect;

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

  // Marcadores de canto (quadrados pretos usados para alinhar a foto).
  static const double ladoMarcador = 16;
  static const double alturaCabecalho = 70;
  static const double alturaRodape = 24;

  // QR code da versão, no canto direito do cabeçalho.
  static const double ladoQr = 48;
  static const double paddingHorizontalCabecalho = 20;

  // Bolinhas das alternativas.
  static const double diametroBolinha = 10;
  static const double bordaBolinha = 0.8;
  static const double espacoBolinhaTexto = 6;
  static const double margemTopoBolinha = 2;

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
}
