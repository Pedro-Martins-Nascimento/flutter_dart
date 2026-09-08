import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  // A ordem tem que bater com a ordem das branches no app_router.dart.
  static const itens = ['Início', 'Turmas', 'Questões', 'Provas', 'Corrigir'];

  final int indiceAtual;
  final ValueChanged<int> aoTocar;

  const AppBottomNav({
    super.key,
    required this.indiceAtual,
    required this.aoTocar,
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
                            child: Text(
                              itens[indice],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    ativo ? FontWeight.w700 : FontWeight.w500,
                                color:
                                    ativo ? AppColors.text : AppColors.textMuted,
                              ),
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

  const AppNavRail({
    super.key,
    required this.indiceAtual,
    required this.aoTocar,
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
                              fontWeight:
                                  ativo ? FontWeight.w700 : FontWeight.w500,
                              color:
                                  ativo ? AppColors.text : AppColors.textMuted,
                            ),
                          ),
                        ),
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
