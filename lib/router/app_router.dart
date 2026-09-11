import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../models/questao.dart';
import '../screens/corrigir/corrigir_screen.dart';
import '../screens/corrigir/corrigir_versao_screen.dart';
import '../screens/corrigir/historico_correcoes_screen.dart';
import '../screens/corrigir/resultado_screen.dart';
import '../screens/inicio/estatistica_completa_screen.dart';
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
import '../services/correcoes_repository.dart';
import '../services/provas_repository.dart';
import '../screens/shell/main_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
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
              builder: (context, state) => const InicioScreen(),
              routes: [
                GoRoute(
                  path: 'estatistica',
                  builder: (context, state) => const EstatisticaCompletaScreen(),
                ),
              ],
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
              builder: (context, state) => const ListarProvasScreen(),
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
              builder: (context, state) => const CorrigirScreen(),
              routes: [
                GoRoute(
                  path: 'versao',
                  builder: (context, state) {
                    final extra = state.extra! as Map<String, Object?>;
                    return CorrigirVersaoScreen(
                      prova: extra['prova']! as ProvaGerada,
                      versao: extra['versao']! as VersaoProva,
                    );
                  },
                ),
                GoRoute(
                  path: 'resultado',
                  builder: (context, state) =>
                      ResultadoScreen(correcao: state.extra! as Correcao),
                ),
                GoRoute(
                  path: 'historico',
                  builder: (context, state) => const HistoricoCorrecoesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
