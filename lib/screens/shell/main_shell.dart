import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_bottom_nav.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        indiceAtual: navigationShell.currentIndex,
        aoTocar: (indice) => navigationShell.goBranch(
          indice,
          // Tocar na aba que já está aberta volta ela pro início.
          initialLocation: indice == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
