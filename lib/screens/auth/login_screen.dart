import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _estiloTexto = TextStyle(fontSize: 17, color: AppColors.text);

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

  String? _validarEmail(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Informe seu e-mail';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? _validarSenha(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Informe sua senha';
    if (texto.length < 6) return 'A senha deve ter ao menos 6 caracteres';
    return null;
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _carregando = false);

    context.go('/criar-prova');
  }

  void _esqueciSenha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recuperação de senha ainda não disponível.')),
    );
  }

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s2),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );

  InputBorder _linha(Color cor, [double espessura = 1]) =>
      UnderlineInputBorder(borderSide: BorderSide(color: cor, width: espessura));

  InputDecoration _decoracao(String hint, {Widget? sufixo}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 17, color: AppColors.neutral500),
        suffixIcon: sufixo,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        border: _linha(AppColors.divider),
        enabledBorder: _linha(AppColors.divider),
        focusedBorder: _linha(AppColors.accent, 1.5),
        errorBorder: _linha(AppColors.error),
        focusedErrorBorder: _linha(AppColors.error, 1.5),
      );

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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),

                    Text(
                      'Correção de provas',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),

                    _rotulo('E-mail'),
                    TextFormField(
                      controller: _emailController,
                      validator: _validarEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: _estiloTexto,
                      decoration: _decoracao('professor@escola.edu.br'),
                    ),
                    const SizedBox(height: AppSpacing.s6),

                    _rotulo('Senha'),
                    TextFormField(
                      controller: _senhaController,
                      validator: _validarSenha,
                      obscureText: !_senhaVisivel,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) {
                        if (!_carregando) _entrar();
                      },
                      style: _estiloTexto,
                      decoration: _decoracao(
                        '••••••••',
                        sufixo: IconButton(
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          tooltip:
                              _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                          onPressed: () =>
                              setState(() => _senhaVisivel = !_senhaVisivel),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.text,
                          disabledBackgroundColor:
                              AppColors.text.withValues(alpha: 0.35),
                        ),
                        onPressed: _carregando ? null : _entrar,
                        child: _carregando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Entrar'),
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
