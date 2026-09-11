import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Bolinha numérica de selo (badge) — usada nos dois estilos de nav pra
// mostrar quantidade pendente (ex: folhas ainda não corrigidas).
class _SeloContador extends StatelessWidget {
  final int quantidade;

  const _SeloContador(this.quantidade);

  @override
  Widget build(BuildContext context) {
    final texto = quantidade > 99 ? '99+' : '$quantidade';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  static const itens = ['Início', 'Turmas', 'Questões', 'Provas', 'Corrigir'];

  final int indiceAtual;
  final ValueChanged<int> aoTocar;
  // índice do item -> quantidade a mostrar no selo (0/ausente = sem selo).
  final Map<int, int> selos;

  const AppBottomNav({
    super.key,
    required this.indiceAtual,
    required this.aoTocar,
    this.selos = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: List.generate(itens.length, (indice) {
                final ativo = indice == indiceAtual;
                return Expanded(
                  child: InkWell(
                    onTap: () => aoTocar(indice),
                    child: Column(
                      children: [
                        Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s2,
                          ),
                          color: ativo ? AppColors.text : Colors.transparent,
                        ),
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    itens[indice],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: ativo
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: ativo
                                          ? AppColors.text
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                if ((selos[indice] ?? 0) > 0) ...[
                                  const SizedBox(width: 4),
                                  _SeloContador(selos[indice]!),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class AppNavRail extends StatelessWidget {
  static const double largura = 208;

  final int indiceAtual;
  final ValueChanged<int> aoTocar;
  final Map<int, int> selos;

  const AppNavRail({
    super.key,
    required this.indiceAtual,
    required this.aoTocar,
    this.selos = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        width: largura,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s6,
                  AppSpacing.s5,
                  AppSpacing.s6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    const Expanded(
                      child: Text(
                        'Correção de provas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(AppBottomNav.itens.length, (indice) {
                final ativo = indice == indiceAtual;
                return InkWell(
                  onTap: () => aoTocar(indice),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: double.infinity,
                          color: ativo ? AppColors.text : Colors.transparent,
                        ),
                        const SizedBox(width: AppSpacing.s5 - 3),
                        Expanded(
                          child: Text(
                            AppBottomNav.itens[indice],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: ativo
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: ativo
                                  ? AppColors.text
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if ((selos[indice] ?? 0) > 0) ...[
                          _SeloContador(selos[indice]!),
                          const SizedBox(width: AppSpacing.s3),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
