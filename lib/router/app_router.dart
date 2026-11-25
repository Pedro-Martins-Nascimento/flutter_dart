import 'dart:typed_data';

import 'package:go_router/go_router.dart';

import '../models/versao_prova.dart';
import '../screens/auth/criar_conta_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/recuperar_senha_screen.dart';
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
import '../screens/questoes/disciplinas_questoes_screen.dart';
import '../screens/questoes/questao_form_screen.dart';
import '../screens/questoes/questoes_disciplina_screen.dart';
import '../screens/turmas/criar_turma_screen.dart';
import '../screens/turmas/disciplina_screen.dart';
import '../screens/turmas/visualizar_turma_screen.dart';
import '../screens/turmas/importar_alunos_screen.dart';
import '../models/correcao.dart';
import '../services/auth_service.dart';
import '../services/correcao_repository.dart';
import '../services/prova_repository.dart';
import '../screens/shell/main_shell.dart';
import '../models/prova_gerada.dart';

GoRouter criarRouter(
  AuthService auth,
  ProvaRepository provas,
  CorrecaoRepository correcoes,
) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth,
  redirect: (context, state) {
    final telaPublica =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/cadastro' ||
        state.matchedLocation == '/recuperar-senha';
    if (!auth.logado) return telaPublica ? null : '/login';
    if (telaPublica) return '/inicio';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/cadastro',
      builder: (context, state) => const CriarContaScreen(),
    ),
    GoRoute(
      path: '/recuperar-senha',
      builder: (context, state) => const RecuperarSenhaScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(
        navigationShell: navigationShell,
        provas: provas,
        correcoes: correcoes,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inicio',
              builder: (context, state) =>
                  InicioScreen(repository: provas, correcoes: correcoes),
              routes: [
                GoRoute(
                  path: 'estatistica',
                  builder: (context, state) =>
                      EstatisticaCompletaScreen(correcoes: correcoes),
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
                  builder: (context, state) => DisciplinaScreen(
                    disciplinaId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'turma/:turmaId',
                      builder: (context, state) => VisualizarTurmaScreen(
                        disciplinaId: state.pathParameters['id']!,
                        turmaId: state.pathParameters['turmaId']!,
                        provas: provas,
                        correcoes: correcoes,
                      ),
                      routes: [
                        GoRoute(
                          path: 'importar',
                          builder: (context, state) => ImportarAlunosScreen(
                            disciplinaId: state.pathParameters['id']!,
                            turmaId: state.pathParameters['turmaId']!,
                          ),
                        ),
                      ],
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
              builder: (context, state) => const DisciplinasQuestoesScreen(),
              routes: [
                GoRoute(
                  path: 'disciplina/:disciplinaId',
                  builder: (context, state) => QuestoesDisciplinaScreen(
                    disciplinaId: state.pathParameters['disciplinaId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'questao',
                      // A questão fica na disciplina: o id dela vai no campo
                      // materiaId da questão.
                      builder: (context, state) => QuestaoFormScreen(
                        materiaId: state.pathParameters['disciplinaId']!,
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
              builder: (context, state) => ListarProvasScreen(
                repository: provas,
                carregarCorrecoes: correcoes.listar,
              ),
            ),
            GoRoute(
              path: '/criar-prova',
              builder: (context, state) {
                final extra = state.extra;
                return CriarProvaScreen(
                  editando: extra is ProvaGerada ? extra : null,
                );
              },
              routes: [
                GoRoute(
                  path: 'questao/:disciplinaId',
                  builder: (context, state) => QuestaoFormScreen(
                    materiaId: state.pathParameters['disciplinaId']!,
                  ),
                ),
              ],
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
              builder: (context, state) =>
                  CorrigirScreen(provas: provas, correcoes: correcoes),
              routes: [
                GoRoute(
                  path: 'versao',
                  builder: (context, state) {
                    final extra = state.extra! as Map<String, Object?>;
                    return CorrigirVersaoScreen(
                      prova: extra['prova']! as ProvaGerada,
                      versao: extra['versao']! as VersaoProva,
                      correcoes: correcoes,
                      foto: extra['foto'] as Uint8List?,
                    );
                  },
                ),
                GoRoute(
                  path: 'resultado',
                  builder: (context, state) => ResultadoScreen(
                    correcao: state.extra! as Correcao,
                    correcoes: correcoes,
                  ),
                ),
                GoRoute(
                  path: 'historico',
                  builder: (context, state) =>
                      HistoricoCorrecoesScreen(correcoes: correcoes),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
