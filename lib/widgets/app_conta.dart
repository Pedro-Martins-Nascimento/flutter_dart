import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

({String nome, String email}) _dadosDaConta(BuildContext context) {
  final usuario = context.watch<AuthService>().usuario;
  final email = usuario?.email ?? '';
  final nome = (usuario?.displayName ?? '').trim();
  return (
    nome: nome.isNotEmpty
        ? nome
        : (email.contains('@') ? email.split('@').first : 'Professor'),
    email: email,
  );
}

String _iniciais(String nome) {
  final partes = nome.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  final primeira = partes.first[0];
  final ultima = partes.length > 1 ? partes.last[0] : '';
  return (primeira + ultima).toUpperCase();
}

Future<void> confirmarSaida(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sair da conta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sair'),
        ),
      ],
    ),
  );
  if (confirmado == true && context.mounted) {
    await context.read<AuthService>().sair();
  }
}

class AppAvatar extends StatelessWidget {
  final String nome;
  final double tamanho;

  const AppAvatar({super.key, required this.nome, this.tamanho = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.accent100,
        shape: BoxShape.circle,
      ),
      child: Text(
        _iniciais(nome),
        style: TextStyle(
          fontSize: tamanho * 0.38,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class AppMenuConta extends StatelessWidget {
  const AppMenuConta({super.key});

  @override
  Widget build(BuildContext context) {
    final conta = _dadosDaConta(context);
    return PopupMenuButton<void>(
      tooltip: 'Conta',
      offset: const Offset(0, 48),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s1),
        child: AppAvatar(nome: conta.nome),
      ),
      itemBuilder: (menuContext) => [
        PopupMenuItem<void>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conta.nome,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              if (conta.email.isNotEmpty)
                Text(
                  conta.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () => confirmarSaida(context),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: AppColors.textMuted),
              SizedBox(width: AppSpacing.s3),
              Text('Sair da conta'),
            ],
          ),
        ),
      ],
    );
  }
}

class AppContaRail extends StatelessWidget {
  const AppContaRail({super.key});

  @override
  Widget build(BuildContext context) {
    final conta = _dadosDaConta(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s2,
        AppSpacing.s3,
        0,
        AppSpacing.s3,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          AppAvatar(nome: conta.nome, tamanho: 32),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conta.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (conta.email.isNotEmpty)
                  Text(
                    conta.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => confirmarSaida(context),
            icon: const Icon(
              Icons.logout_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
