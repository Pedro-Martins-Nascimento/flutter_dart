import 'package:flutter/material.dart';
import 'router/app_router.dart'; // ADICIONADO: config de rotas do go_router
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Correção de Provas',
      // ANTES: era um ThemeData inline com colorScheme.fromSeed(deepPurple).
      // Agora usa o tema central do app (paleta "Modernist" extraída do
      // protótipo), definido em lib/theme/app_theme.dart.
      theme: AppTheme.light,
      // ANTES: home: const GerarProvasScreen(),
      // Agora quem decide a tela inicial é o "initialLocation" lá no
      // app_router.dart (hoje tá apontando pra '/criar-prova').
      // TODO: quando o app tiver login/turmas prontos, o initialLocation
      // do router deve virar a tela de login em vez de '/criar-prova'.
      routerConfig: appRouter,
    );
  }
}

// REMOVIDO (revisão): a MyHomePage/_MyHomePageState era o contador padrão
// que vem quando você roda `flutter create`. Não estava sendo usada em
// lugar nenhum — o MyApp acima já usa MaterialApp.router + appRouter como
// ponto de entrada real. Além de ser código morto, ela tinha um erro de
// sintaxe (`mainAxisAlignment: .center` sem o `MainAxisAlignment` na
// frente), que é o que provavelmente estava aparecendo como erro/sublinhado
// no editor. Removendo em vez de corrigir porque não faz mais sentido
// manter o boilerplate do template no projeto.