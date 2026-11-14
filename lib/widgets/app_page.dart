import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class AppMarca extends StatelessWidget {
  final double tamanho;

  const AppMarca({super.key, this.tamanho = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(tamanho * 0.28),
      ),
      child: Icon(
        Icons.done_all_rounded,
        color: Colors.white,
        size: tamanho * 0.56,
      ),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  final String? kicker;
  final String titulo;
  final Widget? acao;

  const AppPageHeader({
    super.key,
    this.kicker,
    required this.titulo,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return AppFaixa(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s6,
        AppSpacing.s5,
        AppSpacing.s4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null) ...[
                  Text(kicker!.toUpperCase(), style: AppTheme.kicker),
                  const SizedBox(height: 6),
                ],
                Text(titulo, style: AppTheme.tituloPagina),
              ],
            ),
          ),
          if (acao != null) ...[const SizedBox(width: AppSpacing.s3), acao!],
        ],
      ),
    );
  }
}

class AppNovoButton extends StatelessWidget {
  final String rotulo;
  final VoidCallback onPressed;

  const AppNovoButton({
    super.key,
    required this.rotulo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: rotulo,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(rotulo),
      ),
    );
  }
}

class AppListGroup extends StatelessWidget {
  final List<Widget> children;

  const AppListGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: AppSpacing.s5),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class AppListRow extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? leading;
  final Widget? menu;
  final VoidCallback? onTap;

  const AppListRow({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    this.menu,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s4,
          menu == null ? AppSpacing.s4 : AppSpacing.s1,
          AppSpacing.s4,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.s4),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitulo!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (menu != null)
              menu!
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral400,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class AppMenuMais extends StatelessWidget {
  final String tooltip;
  final List<PopupMenuEntry<void>> Function(BuildContext) itens;

  const AppMenuMais({super.key, required this.tooltip, required this.itens});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: tooltip,
      icon: const Icon(
        Icons.more_horiz_rounded,
        size: 22,
        color: AppColors.neutral600,
      ),
      itemBuilder: itens,
    );
  }
}

class AppEstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final Widget? acao;

  const AppEstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s8 * 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.neutral200,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: AppColors.neutral600, size: 26),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (acao != null) ...[const SizedBox(height: AppSpacing.s5), acao!],
        ],
      ),
    );
  }
}
