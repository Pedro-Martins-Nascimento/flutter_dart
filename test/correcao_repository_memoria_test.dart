import 'package:flutter_dart/services/correcao_repository_memoria.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_repository_contrato.dart';

void main() {
  group('CorrecaoRepositoryMemoria', () {
    testarContratoCorrecaoRepository(CorrecaoRepositoryMemoria.new);
  });
}
