import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/correcao.dart';
import '../../services/correcao_repository.dart';
import '../../services/pendentes.dart';
import '../../services/prova_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ProvaRepository provas;
  final CorrecaoRepository correcoes;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.provas,
    required this.correcoes,
  });

  // Posição da aba Corrigir no menu.
  static const _abaCorrigir = 4;

  void _irPara(int indice) => navigationShell.goBranch(
    indice,
    initialLocation: indice == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    // Escuta provas e correções só para o selo de pendentes da aba Corrigir.
    return StreamBuilder<List<ProvaResumo>>(
      stream: provas.observar(),
      builder: (context, provasSnapshot) => StreamBuilder<List<Correcao>>(
        stream: correcoes.observar(),
        builder: (context, correcoesSnapshot) => _menu(
          selos: {
            _abaCorrigir: contarPendentes(
              provasSnapshot.data ?? const <ProvaResumo>[],
              correcoesSnapshot.data ?? const <Correcao>[],
            ),
          },
        ),
      ),
    );
  }

  Widget _menu({required Map<int, int> selos}) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        if (restricoes.maxWidth >= AppLayout.largo) {
          return Scaffold(
            body: Row(
              children: [
                AppNavRail(
                  indiceAtual: navigationShell.currentIndex,
                  aoTocar: _irPara,
                  selos: selos,
                ),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AppBottomNav(
            indiceAtual: navigationShell.currentIndex,
            aoTocar: _irPara,
            selos: selos,
          ),
        );
      },
    );
  }
}
