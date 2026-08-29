// lib/router/app_router.dart
//
// Configuração central de navegação (go_router).

import 'package:go_router/go_router.dart';

import '../models/questao.dart';
import '../screens/provas/criar_prova_screen.dart';
import '../screens/provas/gerar_provas_screen.dart';
import '../screens/provas/preview_layout_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/criar-prova',
  routes: [
    GoRoute(
      path: '/criar-prova',
      builder: (context, state) => const CriarProvaScreen(),
    ),
    GoRoute(
      path: '/gerar-provas',
      builder: (context, state) {
        // Nullable: dá pra cair direto nessa rota sem passar pela Criar
        // Prova (ex: URL digitada na versão web); GerarProvasScreen trata
        // o caso nulo com um fallback.
        final config = state.extra as ProvaConfig?;
        return GerarProvasScreen(config: config);
      },
    ),
    GoRoute(
      path: '/gerar-provas/preview',
      builder: (context, state) {
        final versoes = state.extra as List<VersaoProva>;
        return PreviewLayoutScreen(versoes: versoes);
      },
    ),
  ],
);
