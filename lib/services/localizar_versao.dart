import '../models/versao_prova.dart';
import 'provas_repository.dart' show ProvaGerada;
import 'prova_repository.dart';

typedef VersaoEncontrada = ({ProvaGerada prova, VersaoProva versao});

/// Acha, nas provas já geradas, a versão cujo QR bate com a folha lida.
/// Devolve null se nenhuma bater (por exemplo, um QR de outra coisa).
Future<VersaoEncontrada?> localizarVersaoPorQr(
  ProvaRepository provas,
  String qrCode,
) async {
  for (final resumo in await provas.listar()) {
    final prova = await provas.buscar(resumo.id);
    if (prova == null) continue;
    for (final versao in prova.versoes) {
      if (versao.qrCode == qrCode) return (prova: prova, versao: versao);
    }
  }
  return null;
}
