import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import 'estilo_auth.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _carregando = false;
  String? _emailEnviado;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthService>();
    final email = _emailController.text.trim();
    setState(() => _carregando = true);
    try {
      await auth.enviarRecuperacaoDeSenha(email);
      if (!mounted) return;
      setState(() => _emailEnviado = email);
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
                    'Recuperar senha',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  if (_emailEnviado == null) _formulario() else _confirmacao(),
                  const SizedBox(height: AppSpacing.s3),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s2,
                      ),
                    ),
                    onPressed: _carregando ? null : _voltarParaLogin,
                    child: const Text('Voltar para o login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informe o e-mail da sua conta. Vamos enviar um link para '
            'você criar uma nova senha.',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.s6),
          rotuloAuth('E-mail'),
          TextFormField(
            controller: _emailController,
            validator: validarEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) {
              if (!_carregando) _enviar();
            },
            style: estiloTextoAuth,
            decoration: decoracaoAuth('professor@escola.edu.br'),
          ),
          const SizedBox(height: AppSpacing.s8),
          BotaoPrincipalAuth(
            texto: 'Enviar link',
            carregando: _carregando,
            onPressed: _enviar,
          ),
        ],
      ),
    );
  }

  Widget _confirmacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enviamos um link de recuperação para $_emailEnviado. '
          'Confira também a caixa de spam.',
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.s4),
        TextButton(
          onPressed: () => setState(() => _emailEnviado = null),
          child: const Text('Enviar para outro e-mail'),
        ),
      ],
    );
  }
}
