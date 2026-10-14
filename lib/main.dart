import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/provas_repository.dart';
import 'services/questoes_repository.dart';
import 'services/turmas_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class AppProviders extends StatelessWidget {
  final AuthService auth;
  final Widget child;

  const AppProviders({super.key, required this.auth, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => TurmasRepository()),
        ChangeNotifierProvider(create: (_) => QuestoesRepository()),
        ChangeNotifierProvider(create: (_) => ProvasRepository()),
      ],
      child: child,
    );
  }
}

class MyApp extends StatefulWidget {
  final AuthService? auth;

  const MyApp({super.key, this.auth});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _auth = widget.auth ?? AuthService();
  late final GoRouter _router = criarRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      auth: _auth,
      child: MaterialApp.router(
        title: 'Correção de Provas',

        debugShowCheckedModeBanner: false,

        theme: AppTheme.light,

        routerConfig: _router,
      ),
    );
  }
}
