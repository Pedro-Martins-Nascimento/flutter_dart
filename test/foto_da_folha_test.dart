import 'dart:typed_data';

import 'package:flutter_dart/services/foto_da_folha.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('foto 4K é reduzida para caber no documento do Firestore', () {
    // Foto em pé de 2160x3840 com ruído (JPEG grande).
    final foto = img.Image(width: 2160, height: 3840);
    for (var y = 0; y < foto.height; y++) {
      for (var x = 0; x < foto.width; x++) {
        final v = (x * 31 + y * 17) % 256;
        foto.setPixelRgb(x, y, v, 255 - v, (x ^ y) % 256);
      }
    }
    final original = img.encodeJpg(foto, quality: 95);

    final guardada = prepararFotoDaFolha(original);

    expect(guardada, isNotNull);
    expect(
      guardada!.length,
      lessThanOrEqualTo(LimitesFotoGuardada.bytesMaximo),
    );
    final lida = img.decodeJpg(guardada)!;
    expect(lida.height, LimitesFotoGuardada.ladoMaximo);
    expect(lida.width, 900);
  });

  test('foto pequena mantém o tamanho', () {
    final foto = img.Image(width: 400, height: 600);
    final guardada = prepararFotoDaFolha(img.encodeJpg(foto));
    final lida = img.decodeJpg(guardada!)!;
    expect((lida.width, lida.height), (400, 600));
  });

  test('bytes que não são imagem não são guardados', () {
    expect(prepararFotoDaFolha(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
