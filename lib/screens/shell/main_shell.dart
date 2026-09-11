import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/correcoes_repository.dart';
import '../../services/provas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../corrigir/corrigir_screen.dart' show contarPendentes;

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _irPara(int indice) => navigationShell.goBranch(
    indice,
    initialLocation: indice == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    // Escuta os dois repositórios só pra recalcular o selo de pendentes
    // da aba Corrigir sem precisar entrar na tela pra saber se tem algo
    // esperando.
    return ListenableBuilder(
      listenable: Listenable.merge([
        ProvasRepository.instance,
        CorrecoesRepository.instance,
      ]),
      builder: (context, _) {
        final selos = {4: contarPendentes()};

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
      },
    );
  }
}
