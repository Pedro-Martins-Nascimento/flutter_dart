import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const estiloTextoAuth = TextStyle(fontSize: 17, color: AppColors.text);

final _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validarEmail(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Informe seu e-mail';
  if (!_regexEmail.hasMatch(texto)) return 'E-mail inválido';
  return null;
}

String? validarSenha(String? valor) {
  final texto = valor ?? '';
  if (texto.isEmpty) return 'Informe sua senha';
  if (texto.length < 6) return 'A senha deve ter ao menos 6 caracteres';
  return null;
}

Widget rotuloAuth(String texto) => Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.s2),
  child: Text(
    texto,
    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
  ),
);

InputBorder _linha(Color cor, [double espessura = 1]) => UnderlineInputBorder(
  borderSide: BorderSide(color: cor, width: espessura),
);

InputDecoration decoracaoAuth(String hint, {Widget? sufixo}) => InputDecoration(
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

class BotaoPrincipalAuth extends StatelessWidget {
  final String texto;
  final bool carregando;
  final VoidCallback onPressed;

  const BotaoPrincipalAuth({
    super.key,
    required this.texto,
    required this.carregando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.text,
          disabledBackgroundColor: AppColors.text.withValues(alpha: 0.35),
        ),
        onPressed: carregando ? null : onPressed,
        child: carregando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(texto),
      ),
    );
  }
}

class BotaoVerSenha extends StatelessWidget {
  final bool visivel;
  final VoidCallback onPressed;

  const BotaoVerSenha({
    super.key,
    required this.visivel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: AppColors.textMuted,
      ),
      tooltip: visivel ? 'Ocultar senha' : 'Mostrar senha',
      onPressed: onPressed,
    );
  }
}
