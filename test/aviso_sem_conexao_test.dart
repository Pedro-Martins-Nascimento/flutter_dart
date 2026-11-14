import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_dart/services/conexao_service.dart';
import 'package:flutter_dart/widgets/aviso_sem_conexao.dart';

Widget _tela(ConexaoService conexao) {
  return ChangeNotifierProvider.value(
    value: conexao,
    child: const MaterialApp(home: Scaffold(body: AvisoSemConexao())),
  );
}

void main() {
  testWidgets('exibe aviso quando está offline', (tester) async {
    await tester.pumpWidget(_tela(ConexaoService(onlineInicial: false)));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Sem conexão com a internet. Algumas ações podem não ser salvas.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('não exibe aviso quando está online', (tester) async {
    await tester.pumpWidget(_tela(ConexaoService(onlineInicial: true)));
    await tester.pumpAndSettle();

    expect(find.byType(AvisoSemConexao), findsOneWidget);
    expect(
      find.text(
        'Sem conexão com a internet. Algumas ações podem não ser salvas.',
      ),
      findsNothing,
    );
  });
}
