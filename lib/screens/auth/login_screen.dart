import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import 'estilo_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthService>();
    await _tentar(
      () => auth.entrarComEmail(
        _emailController.text.trim(),
        _senhaController.text,
      ),
    );
  }

  Future<void> _entrarComGoogle() async {
    final auth = context.read<AuthService>();
    await _tentar(auth.entrarComGoogle);
  }

  Future<void> _tentar(Future<void> Function() acao) async {
    setState(() => _carregando = true);
    try {
      await acao();
    } on AuthErro catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(erro.mensagem)));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _esqueciSenha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperação de senha ainda não disponível.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s6,
              vertical: AppSpacing.s8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppMarca(tamanho: 48),
                    const SizedBox(height: AppSpacing.s8),

                    Text(
                      'Correção de provas',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),

                    rotuloAuth('E-mail'),
                    TextFormField(
                      controller: _emailController,
                      validator: validarEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: estiloTextoAuth,
                      decoration: decoracaoAuth('professor@escola.edu.br'),
                    ),
                    const SizedBox(height: AppSpacing.s6),

                    rotuloAuth('Senha'),
                    TextFormField(
                      controller: _senhaController,
                      validator: validarSenha,
                      obscureText: !_senhaVisivel,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) {
                        if (!_carregando) _entrar();
                      },
                      style: estiloTextoAuth,
                      decoration: decoracaoAuth(
                        '••••••••',
                        sufixo: BotaoVerSenha(
                          visivel: _senhaVisivel,
                          onPressed: () =>
                              setState(() => _senhaVisivel = !_senhaVisivel),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),

                    BotaoPrincipalAuth(
                      texto: 'Entrar',
                      carregando: _carregando,
                      onPressed: _entrar,
                    ),
                    const SizedBox(height: AppSpacing.s3),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _carregando ? null : _entrarComGoogle,
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        label: const Text('Entrar com Google'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),

                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s2,
                        ),
                      ),
                      onPressed: _esqueciSenha,
                      child: const Text('Esqueci minha senha'),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: AppSpacing.s4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Ainda não tem conta?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: _carregando
                              ? null
                              : () => context.push('/cadastro'),
                          child: const Text('Criar conta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
