import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Pede onde salvar e grava a planilha. Devolve false se o professor cancelar.
/// No navegador o arquivo é baixado; no desktop o seletor só devolve o
/// caminho, então o arquivo é gravado aqui.
Future<bool> salvarXlsx(String nome, Uint8List bytes) async {
  final destino = await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar relatório de notas',
    fileName: nome,
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    bytes: bytes,
  );
  if (destino == null) return false;

  final desktop =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);
  if (desktop) {
    final caminho = destino.toLowerCase().endsWith('.xlsx')
        ? destino
        : '$destino.xlsx';
    await File(caminho).writeAsBytes(bytes);
  }
  return true;
}
