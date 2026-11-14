import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<bool> _salvarArquivo({
  required String nome,
  required Uint8List bytes,
  required String extensao,
  required String titulo,
}) async {
  final destino = await FilePicker.platform.saveFile(
    dialogTitle: titulo,
    fileName: nome,
    type: FileType.custom,
    allowedExtensions: [extensao],
    bytes: bytes,
  );
  // No navegador null não significa cancelamento: o download já começou.
  if (destino == null) return kIsWeb;

  final desktop =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);
  if (desktop) {
    final caminho = destino.toLowerCase().endsWith('.$extensao')
        ? destino
        : '$destino.$extensao';
    await File(caminho).writeAsBytes(bytes);
  }
  return true;
}

/// Pede onde salvar e grava a planilha. Devolve false se o professor cancelar.
Future<bool> salvarXlsx(String nome, Uint8List bytes) => _salvarArquivo(
  nome: nome,
  bytes: bytes,
  extensao: 'xlsx',
  titulo: 'Salvar relatório de notas',
);

/// Pede onde salvar e grava o documento Word. Devolve false se cancelar.
Future<bool> salvarDocx(String nome, Uint8List bytes) => _salvarArquivo(
  nome: nome,
  bytes: bytes,
  extensao: 'docx',
  titulo: 'Salvar prova em Word',
);
