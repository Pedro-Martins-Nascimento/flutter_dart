// lib/router/app_router.dart
//
// Configuração central de navegação com go_router.
// Cada tela do app vira uma rota aqui. Por enquanto só temos as
// telas de provas, mas o resto do grupo (turmas, questões,
// correção...) vai entrar nessa mesma lista conforme for ficando pronto.

import 'package:go_router/go_router.dart';

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
      builder: (context, state) => const GerarProvasScreen(),
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