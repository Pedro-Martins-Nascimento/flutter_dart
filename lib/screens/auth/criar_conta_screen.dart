import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import 'estilo_auth.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  String? _validarNome(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Informe seu nome';
    if (texto.length < 3) return 'Nome muito curto';
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if ((valor ?? '').isEmpty) return 'Repita a senha';
    if (valor != _senhaController.text) return 'As senhas não conferem';
    return null;
  }

  Future<void> _criarConta() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthService>();
    setState(() => _carregando = true);
    try {
      await auth.criarConta(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
    } on AuthErro catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(erro.mensagem)));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _voltarParaLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
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
                child: AutofillGroup(
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
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),

                      rotuloAuth('Nome'),
                      TextFormField(
                        controller: _nomeController,
                        validator: _validarNome,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        style: estiloTextoAuth,
                        decoration: decoracaoAuth('Seu nome completo'),
                      ),
                      const SizedBox(height: AppSpacing.s6),

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
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        style: estiloTextoAuth,
                        decoration: decoracaoAuth(
                          'Mínimo de 6 caracteres',
                          sufixo: BotaoVerSenha(
                            visivel: _senhaVisivel,
                            onPressed: () =>
                                setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s6),

                      rotuloAuth('Confirmar senha'),
                      TextFormField(
                        controller: _confirmacaoController,
                        validator: _validarConfirmacao,
                        obscureText: !_senhaVisivel,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onFieldSubmitted: (_) {
                          if (!_carregando) _criarConta();
                        },
                        style: estiloTextoAuth,
                        decoration: decoracaoAuth('Repita a senha'),
                      ),
                      const SizedBox(height: AppSpacing.s8),

                      BotaoPrincipalAuth(
                        texto: 'Criar conta',
                        carregando: _carregando,
                        onPressed: _criarConta,
                      ),
                      const SizedBox(height: AppSpacing.s3),

                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s2,
                          ),
                        ),
                        onPressed: _carregando ? null : _voltarParaLogin,
                        child: const Text('Já tenho conta · Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
