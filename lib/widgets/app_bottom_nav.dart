import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_page.dart';

/// Bolinha com a quantidade pendente de um item do menu.
class _SeloContador extends StatelessWidget {
  final int quantidade;

  const _SeloContador(this.quantidade);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        quantidade > 99 ? '99+' : '$quantidade',
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

class _ItemNav {
  final String rotulo;
  final IconData icone;
  final IconData iconeAtivo;

  const _ItemNav(this.rotulo, this.icone, this.iconeAtivo);
}

const _itensNav = [
  _ItemNav('Início', Icons.home_outlined, Icons.home_rounded),
  _ItemNav('Turmas', Icons.groups_outlined, Icons.groups_rounded),
  _ItemNav('Questões', Icons.quiz_outlined, Icons.quiz_rounded),
  _ItemNav('Provas', Icons.description_outlined, Icons.description_rounded),
  _ItemNav(
    'Corrigir',
    Icons.document_scanner_outlined,
    Icons.document_scanner_rounded,
  ),
];

Widget _iconeComSelo(_ItemNav item, bool ativo, int selo, Color cor) {
  final icone = Icon(
    ativo ? item.iconeAtivo : item.icone,
    size: 22,
    color: cor,
  );
  if (selo <= 0) return icone;
  return Badge(
    backgroundColor: AppColors.accent,
    textColor: Colors.white,
    label: Text(selo > 99 ? '99+' : '$selo'),
    child: icone,
  );
}

class AppBottomNav extends StatelessWidget {
  static final itens = [for (final item in _itensNav) item.rotulo];

  final int indiceAtual;
  final ValueChanged<int> aoTocar;

  /// Índice do item -> quantidade a mostrar no selo (0 ou ausente = sem selo).
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
            height: 64,
            child: Row(
              children: List.generate(_itensNav.length, (indice) {
                final item = _itensNav[indice];
                final ativo = indice == indiceAtual;
                final cor = ativo ? AppColors.text : AppColors.neutral500;
                return Expanded(
                  child: Semantics(
                    selected: ativo,
                    button: true,
                    child: InkResponse(
                      onTap: () => aoTocar(indice),
                      radius: 36,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ativo
                                  ? AppColors.neutral200
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: _iconeComSelo(
                              item,
                              ativo,
                              selos[indice] ?? 0,
                              cor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.rotulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: ativo
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: cor,
                            ),
                          ),
                        ],
                      ),
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
  static const double largura = 232;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s2,
                    AppSpacing.s6,
                    AppSpacing.s2,
                    AppSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      AppMarca(tamanho: 30),
                      SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(
                          'Correção de provas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...List.generate(_itensNav.length, (indice) {
                  final item = _itensNav[indice];
                  final ativo = indice == indiceAtual;
                  final cor = ativo ? AppColors.text : AppColors.textMuted;
                  final selo = selos[indice] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: ativo ? AppColors.neutral200 : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () => aoTocar(indice),
                        child: SizedBox(
                          height: 42,
                          child: Row(
                            children: [
                              const SizedBox(width: AppSpacing.s3),
                              Icon(
                                ativo ? item.iconeAtivo : item.icone,
                                size: 20,
                                color: cor,
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                child: Text(
                                  item.rotulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: ativo
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: cor,
                                  ),
                                ),
                              ),
                              if (selo > 0) ...[
                                _SeloContador(selo),
                                const SizedBox(width: AppSpacing.s3),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
