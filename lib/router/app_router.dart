import 'package:go_router/go_router.dart';

import '../models/versao_prova.dart';
import '../screens/auth/login_screen.dart';
import '../models/questao.dart';
import '../screens/corrigir/corrigir_screen.dart';
import '../screens/inicio/inicio_screen.dart';
import '../screens/provas/criar_prova_screen.dart';
import '../screens/provas/gerar_provas_screen.dart';
import '../screens/provas/listar_provas_screen.dart';
import '../screens/provas/preview_layout_screen.dart';
import '../screens/questoes/materias_screen.dart';
import '../screens/questoes/questao_form_screen.dart';
import '../screens/questoes/questoes_materia_screen.dart';
import '../screens/turmas/criar_turma_screen.dart';
import '../screens/turmas/visualizar_turma_screen.dart';
import '../screens/turmas/importar_alunos_screen.dart';
import '../services/auth_service.dart';
import '../services/provas_repository.dart';
import '../services/prova_repository.dart';
import '../screens/shell/main_shell.dart';

GoRouter criarRouter(AuthService auth, ProvaRepository provas) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth,
  redirect: (context, state) {
    final naTelaDeLogin = state.matchedLocation == '/login';
    if (!auth.logado) return naTelaDeLogin ? null : '/login';
    if (naTelaDeLogin) return '/inicio';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inicio',
              builder: (context, state) =>
                  InicioScreen(repository: provas),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/turmas',
              builder: (context, state) => const CriarTurmaScreen(),
              routes: [
                GoRoute(
                  path: 'nova',
                  builder: (context, state) => const NovaTurmaScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return VisualizarTurmaScreen(turmaId: id);
                  },
                  routes: [
                    GoRoute(
                      path: 'importar',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return ImportarAlunosScreen(turmaId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/questoes',
              builder: (context, state) => const MateriasScreen(),
              routes: [
                GoRoute(
                  path: ':materiaId',
                  builder: (context, state) => QuestoesMateriaScreen(
                    materiaId: state.pathParameters['materiaId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'questao',
                      builder: (context, state) => QuestaoFormScreen(
                        materiaId: state.pathParameters['materiaId']!,
                        questao: state.extra as Questao?,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/provas-geradas',
              builder: (context, state) =>
                  ListarProvasScreen(repository: provas),
            ),
            GoRoute(
              path: '/criar-prova',
              builder: (context, state) => const CriarProvaScreen(),
            ),
            GoRoute(
              path: '/gerar-provas',

              builder: (context, state) {
                final extra = state.extra;
                if (extra is ProvaGerada) {
                  return GerarProvasScreen(
                    repository: provas,
                    provaExistente: extra,
                  );
                }
                return GerarProvasScreen(
                  repository: provas,
                  dados: extra as DadosProva?,
                );
              },
              routes: [
                GoRoute(
                  path: 'preview',
                  builder: (context, state) {
                    // Sem os dados na navegação (ex.: página recarregada), lê a
                    // prova do repository pelo ?provaId=.
                    final extra = state.extra;
                    if (extra is PreviewLayoutArgs) {
                      return PreviewLayoutScreen(
                        versoes: extra.versoes,
                        alunos: extra.alunos,
                      );
                    }
                    if (extra is List<VersaoProva>) {
                      return PreviewLayoutScreen(versoes: extra);
                    }
                    return PreviewLayoutScreen.deProva(
                      repository: provas,
                      provaId: state.uri.queryParameters['provaId'] ?? '',
                    );
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
              builder: (context, state) => const CorrigirScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
