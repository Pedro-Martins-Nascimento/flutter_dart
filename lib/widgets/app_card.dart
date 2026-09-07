// lib/widgets/app_card.dart
//
// Componentes reutilizáveis de "card" no estilo soft/iOS-like do app.
//
// A ideia: dá pra colocar cor, raio de canto, tipografia etc. no
// ThemeData (e isso já foi feito em app_theme.dart) — mas o "card de
// item" da tela de referência (ícone + título + subtítulo + ações à
// direita) é uma COMPOSIÇÃO de vários widgets, não um único componente
// do Material. Isso o tema sozinho não resolve. Por isso os widgets
// abaixo: cada tela usa AppCard/AppListItem em vez de montar
// Card+Row+Column na mão, e o visual fica igual em todo o app mesmo
// mudando o conteúdo.
//
// AppCard        -> "casca" genérica: fundo branco + sombra suave +
//                    cantos arredondados. Aceita qualquer widget dentro.
// AppLeadingIcon  -> ícone/miniatura arredondada pra usar como "leading"
//                    (ex: ícone de QR code, ícone da matéria...).
// AppListItem     -> item de lista pronto: leading + título + subtítulo
//                    + trailing (ações à direita) + footer opcional
//                    (ex: um dropdown, igual usávamos no card de versão).

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Scaffold "padrão" das telas do app — funciona igual ao Scaffold
/// normal do Flutter, mas já aplica o AppMaxWidth no `body` sozinho,
/// sem precisar lembrar de envolver cada tela manualmente.
///
/// OBS PRA EQUIPE: criei esse wrapper por conta própria (Karen) pra
/// resolver as telas ficando muito esticadas quando o app roda em
/// desktop/iPad/web — o Scaffold puro do Flutter não tem limite de
/// largura por padrão. Não é nada do enunciado/requisito, só ajuste de
/// UI. Se alguma tela precisar do Scaffold sem esse limite (ex: uma
/// tela cheia, tipo splash/onboarding), é só usar o Scaffold normal em
/// vez desse
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final double maxWidth;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.maxWidth = AppLayout.maxContentWidth,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      body: body == null ? null : AppMaxWidth(maxWidth: maxWidth, child: body!),
    );
  }
}

/// Limita a largura do CONTEÚDO da tela e centraliza — evita que listas,
/// forms e cards fiquem esticados de ponta a ponta quando o app roda em
/// telas largas (desktop, iPad, web). Em celular (largura menor que o
/// limite) fica exatamente igual a hoje, sem nenhuma diferença visual.
///
/// Uso: coloca direto no `body:` do Scaffold, por fora do
/// ListView/Column da tela:
///
/// ```dart
/// body: const AppMaxWidth(
///   child: ListView(...),
/// ),
/// ```
///
/// [maxWidth] tem como padrão [AppLayout.maxContentWidth]; use
/// [AppLayout.maxContentWidthWide] em telas com colunas lado a lado.
class AppMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AppMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Casca de card usada em todo o app: fundo branco, cantos bem
/// arredondados, sombra suave (em vez da borda reta do Card padrão do
/// Material com elevation).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s4),
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: border,
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;

    // Material + InkWell por cima pra manter o efeito de toque (ripple)
    // mesmo com o card usando BoxDecoration em vez do Card do Material.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Ícone/miniatura pequena e arredondada — usada como "leading" de um
/// AppListItem. Por padrão usa o tint claro do bordô (accent100), pra
/// não competir visualmente com o bordô sólido dos botões.
class AppLeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;
  final double size;

  const AppLeadingIcon({
    super.key,
    required this.icon,
    this.background = AppColors.accent100,
    this.color = AppColors.accent,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Item de lista no estilo "card" — é o componente que reproduz o
/// visual da tela de referência (ícone + título + subtítulo + ações).
///
/// - [leading]: normalmente um AppLeadingIcon, mas aceita qualquer widget.
/// - [title] / [subtitle]: textos principais do item.
/// - [trailing]: área livre à direita (ícone, IconButton, etc.).
/// - [footer]: espaço opcional abaixo do título/subtítulo, dentro do
///   MESMO card — útil pra um dropdown, chip de status, etc., sem
///   precisar empilhar outro card embaixo.
/// - [selected]: quando true, pinta o card com o tint claro do bordô e
///   uma borda fina — usado pra itens selecionáveis (ex: questão
///   marcada numa lista).
class AppListItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool selected;

  const AppListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.footer,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s3),
      backgroundColor: selected ? AppColors.accent100 : null,
      border: selected ? Border.all(color: AppColors.accent, width: 1.2) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.s2),
                trailing!,
              ],
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.s3),
            footer!,
          ],
        ],
      ),
    );
  }
}