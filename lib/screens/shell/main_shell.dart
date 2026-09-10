import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _irPara(int indice) => navigationShell.goBranch(
    indice,
    initialLocation: indice == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        if (restricoes.maxWidth >= AppLayout.largo) {
          return Scaffold(
            body: Row(
              children: [
                AppNavRail(
                  indiceAtual: navigationShell.currentIndex,
                  aoTocar: _irPara,
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
          ),
        );
      },
    );
  }
}
