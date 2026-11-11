import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter_dart/services/layout_folha.dart';

void main() {
  test('a página tem as medidas do A4 do pacote pdf', () {
    expect(LayoutFolha.larguraPagina, closeTo(PdfPageFormat.a4.width, 0.001));
    expect(LayoutFolha.alturaPagina, closeTo(PdfPageFormat.a4.height, 0.001));
  });

  test('os 4 marcadores ficam nos cantos da área útil, com o mesmo lado', () {
    final m = LayoutFolha.marcadoresDeCanto();
    expect(m, hasLength(4));
    expect(m[0].topLeft, const Offset(28, 28));
    expect(m[1].right, LayoutFolha.larguraPagina - 28);
    expect(m[2].bottom, LayoutFolha.alturaPagina - 28);
    expect(m[3].bottomRight,
        Offset(LayoutFolha.larguraPagina - 28, LayoutFolha.alturaPagina - 28));
    for (final r in m) {
      expect(r.width, LayoutFolha.ladoMarcador);
      expect(r.height, LayoutFolha.ladoMarcador);
    }
  });

  test('mudar a margem desloca os marcadores', () {
    final m = LayoutFolha.marcadoresDeCanto(margem: 40);
    expect(m[0].topLeft, const Offset(40, 40));
    expect(m[3].right, LayoutFolha.larguraPagina - 40);
  });

  test('o QR fica dentro da página e não encosta no marcador direito', () {
    final qr = LayoutFolha.areaQr();
    final marcadorDireito = LayoutFolha.marcadoresDeCanto()[1];
    expect(qr.width, LayoutFolha.ladoQr);
    expect(qr.right, lessThan(marcadorDireito.left));
    expect(
      const Rect.fromLTWH(0, 0, LayoutFolha.larguraPagina,
              LayoutFolha.alturaPagina)
          .contains(qr.bottomRight),
      isTrue,
    );
  });
}
