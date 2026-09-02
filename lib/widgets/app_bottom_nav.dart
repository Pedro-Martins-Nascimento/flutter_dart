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
