import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/em_breve_screen.dart';
import '../screens/provas/criar_prova_screen.dart';
import '../screens/provas/gerar_provas_screen.dart';
import '../screens/provas/listar_provas_screen.dart';
import '../screens/provas/preview_layout_screen.dart';
import '../services/provas_repository.dart'; // ProvaGerada
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
              // ALTERADO: agora recebe (opcionalmente) o DadosProva montado na
              // tela Criar Prova. `as DadosProva?` porque a rota pode ser aberta
              // sem `extra` (ex: navegação direta) — nesse caso GerarProvasScreen
              // cai nos valores mock de sempre.
              //
              // NOVO: também aceita um ProvaGerada — usado quando a tela é aberta
              // a partir do histórico ("Provas geradas"), pra reabrir uma rodada
              // já gerada e permitir trocar o vínculo aluno/versão antes de ir
              // pro Editor de layout / Exportar PDF.
              builder: (context, state) {
                final extra = state.extra;
                if (extra is ProvaGerada) {
                  return GerarProvasScreen(provaExistente: extra);
                }
                return GerarProvasScreen(dados: extra as DadosProva?);
              },
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
    // NOVO: histórico de provas geradas.
    GoRoute(
      path: '/provas-geradas',
      builder: (context, state) => const ListarProvasScreen(),
    ),
  ],
);
