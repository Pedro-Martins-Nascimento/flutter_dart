import '../models/correcao.dart';
import 'prova_repository.dart' show ProvaResumo;

/// Quantas versões já geradas ainda não têm correção salva.
int contarPendentes(List<ProvaResumo> provas, List<Correcao> correcoes) {
  final geradas = provas.fold<int>(0, (soma, p) => soma + p.totalVersoes);
  return (geradas - correcoes.length).clamp(0, geradas);
}
