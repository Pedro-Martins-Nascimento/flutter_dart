// lib/theme/app_theme.dart
//
// Tema central do app. (pode ser alterado, só uma ideia inicial)

// Aplicando isso no MaterialApp.router, os widgets padrão (botões, inputs,
// chips, cards, tabelas...) já nascem no estilo certo em todas as telas.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Fundo neutro claro (não branco puro) — dá a sensação "soft" do
  // estilo iOS, em vez do branco cru do Material padrão.
  static const bg = Color(0xFFF4F2F3);

  // Cards ficam brancos puros, destacando do fundo neutro.
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF7F1F2); // fundo alternativo bem sutil (ex: linha zebrada)

  static const text = Color(0xFF241417); // quase preto, com leve tom bordô
  static const textMuted = Color(0xFF7A6E70); // cinza pra subtítulos/legendas

  // Vermelho-bordô institucional (Católica de SC) — cor de destaque
  // principal, mas usada só em pontos pontuais: botão primário, item
  // selecionado, ícone ativo, etc. Não pinta a tela inteira.
  static const accent = Color(0xFF7A1B2E); // bordô escuro (like da logo/portal)
  static const accentLight = Color(0xFFB33951); // vermelho mais claro, usado em botões/estados hover
  static const accent100 = Color(0xFFF6E8EA); // tint bem claro do bordô, pra fundo de chip selecionado etc.

  // Amarelo/laranja institucional (aparece nos ícones do portal do
  // aluno) — reservado pra avisos/alertas pontuais, igual ao "Total cost
  // exceeds..." do exemplo de referência.
  static const warning = Color(0xFFE0A63C);
  static const warning100 = Color(0xFFFCF3E1);

  static const divider = Color(0xFFE6E1E2);

  static const neutral100 = Color(0xFFF8F6F6);
  static const neutral200 = Color(0xFFEFEBEC);
  static const neutral300 = Color(0xFFDFD9DA);
  static const neutral400 = Color(0xFFC2BABC);
  static const neutral500 = Color(0xFFA79D9F);
  static const neutral600 = Color(0xFF8B8082);
  static const neutral700 = Color(0xFF6B6062);
  static const neutral800 = Color(0xFF4A4143);
  static const neutral900 = Color(0xFF2D2628);

  static const success = Color(0xFF3A8351);
  static const error = Color(0xFFB3261E);
}

// Limites de largura do conteúdo — usados pra centralizar as telas em
// vez de deixá-las esticadas de ponta a ponta quando o app roda em
// telas largas (desktop, iPad, web). Ver AppMaxWidth em app_card.dart.
class AppLayout {
  AppLayout._();

  // Largura confortável pra listas/formulários de uma coluna só.
  static const double maxContentWidth = 640.0;

  // Um pouco mais largo — usado em telas que têm colunas lado a lado
  // (ex: botões "Exportar PDF" / "Editor de layout" da tela Gerar Provas).
  static const double maxContentWidthWide = 800.0;
}

class AppSpacing {
  AppSpacing._();
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}

// Raios de canto — parte central da estética "soft/iOS-like": tudo
// arredondado, nada de BorderRadius.zero.
class AppRadius {
  AppRadius._();
  static const sm = 10.0; // inputs, chips pequenos
  static const md = 14.0; // botões
  static const lg = 20.0; // cards, containers de destaque
  static const full = 999.0; // pills, avatares
}

class AppTheme {
  AppTheme._();

  // Estilo de "kicker" — label pequeno, maiúsculo, discreto (cinza, não
  // mais na cor de destaque) — usado pra títulos de seção nas telas
  // (ex: "1. Selecione a(s) matéria(s)"). Deixou de ser vermelho porque a
  // ideia agora é reservar o bordô só pra elementos realmente
  // acionáveis/importantes (botão, seleção), não pra texto de apoio.
  static TextStyle get kicker => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.textMuted,
      );

  // Sombra suave padrão dos cards (substitui a borda reta cinza da
  // versão anterior).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.neutral900.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.error,
      ),
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textMuted,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        centerTitle: true,
      ),

      // Botões — cantos bem arredondados, peso 700. O vermelho-bordô
      // aparece aqui de propósito: é a ação principal da tela, então é
      // um dos poucos lugares em que a cor de destaque "grita".
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? Colors.white.withValues(alpha: 0.12)
                : null,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Inputs — fundo neutro clarinho, cantos arredondados, sem borda
      // pesada; foco usa o bordô, mas fino (1.5px), não um bloco de cor.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s4,
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),

      // Cards — fundo branco, cantos bem arredondados, sombra suave em
      // vez de borda reta cinza. É a peça central do visual "soft".
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      // Chips (FilterChip da tela Criar Prova) — selecionado usa o tint
      // claro do bordô (accent100) em vez do bordô sólido, pra não virar
      // um bloco vermelho grande na tela; só o texto/ícone fica na cor
      // cheia.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral100,
        selectedColor: AppColors.accent100,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.neutral400,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.neutral400, width: 1.5),
      ),

      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textMuted,
        ),
        dividerThickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}