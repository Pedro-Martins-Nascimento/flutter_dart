// Foto da folha guardada junto da correção: reduzida para caber num
// documento do Firestore (limite de 1 MiB) e ainda dar para ler as marcações.

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class LimitesFotoGuardada {
  LimitesFotoGuardada._();

  /// Lado maior da foto guardada, em pixels.
  static const int ladoMaximo = 1600;

  /// Tamanho máximo do JPEG guardado (folga sob o limite de 1 MiB do
  /// documento do Firestore).
  static const int bytesMaximo = 800 * 1024;

  static const int qualidadeInicial = 80;
  static const int qualidadeMinima = 40;
}

/// Prepara a foto para guardar. Devolve null se ela não abrir ou não couber
/// no limite nem com a menor qualidade.
Uint8List? prepararFotoDaFolha(Uint8List original) {
  final img.Image? imagem;
  try {
    imagem = img.decodeImage(original);
  } catch (_) {
    return null;
  }
  if (imagem == null) return null;
  final maior = imagem.width > imagem.height ? imagem.width : imagem.height;
  final reduzida = maior > LimitesFotoGuardada.ladoMaximo
      ? img.copyResize(
          imagem,
          width: imagem.width >= imagem.height
              ? LimitesFotoGuardada.ladoMaximo
              : null,
          height: imagem.height > imagem.width
              ? LimitesFotoGuardada.ladoMaximo
              : null,
          interpolation: img.Interpolation.average,
        )
      : imagem;
  for (
    var qualidade = LimitesFotoGuardada.qualidadeInicial;
    qualidade >= LimitesFotoGuardada.qualidadeMinima;
    qualidade -= 10
  ) {
    final jpeg = img.encodeJpg(reduzida, quality: qualidade);
    if (jpeg.length <= LimitesFotoGuardada.bytesMaximo) return jpeg;
  }
  return null;
}

/// [prepararFotoDaFolha] fora da thread da tela.
Future<Uint8List?> prepararFotoEmSegundoPlano(Uint8List original) =>
    compute(prepararFotoDaFolha, original);
