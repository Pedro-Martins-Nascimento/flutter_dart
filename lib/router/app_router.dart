import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/em_breve_screen.dart';
import '../screens/provas/criar_prova_screen.dart';
import '../screens/provas/gerar_provas_screen.dart';
import '../screens/provas/preview_layout_screen.dart';
import '../screens/shell/main_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // A ordem das branches tem que bater com AppBottomNav.itens.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inicio',
              builder: (context, state) => const EmBreveScreen(titulo: 'Início'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/turmas',
              builder: (context, state) => const EmBreveScreen(titulo: 'Turmas'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/questoes',
              builder: (context, state) =>
                  const EmBreveScreen(titulo: 'Questões'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/criar-prova',
              builder: (context, state) => const CriarProvaScreen(),
            ),
            GoRoute(
              path: '/gerar-provas',
              builder: (context, state) => const GerarProvasScreen(),
              routes: [
                GoRoute(
                  path: 'preview',
                  builder: (context, state) {
                    final versoes = state.extra as List<VersaoProva>;
                    return PreviewLayoutScreen(versoes: versoes);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/corrigir',
              builder: (context, state) =>
                  const EmBreveScreen(titulo: 'Corrigir'),
            ),
          ],
        ),
      ],
    ),
  ],
);
