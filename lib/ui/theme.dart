import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de cor do design system do CP4 (Figma "CP1" > Color).
/// Use sempre estes nomes em vez de escrever o hexadecimal nas telas.
class AppColors {
  AppColors._();

  // Main
  static const Color orange = Color(0xFFFD6737); // primary
  static const Color teal = Color(0xFF009688); // secondary: economia / melhor preço
  static const Color pink = Color(0xFFED5E91); // destaques suaves
  static const Color tertiary = Color(0xFFE91E63); // tags promocionais
  static const Color error = Color(0xFFE05744);
  static const Color peach = Color(0xFFFECEBF); // apoio para fundos de card

  // Button
  static const Color buttonDefault = orange;
  static const Color buttonHover = Color(0xFFD73E1C);
  static const Color buttonDisabled = Color(0xFFB3B3B3);

  // Stroke
  static const Color strokeGrey = Color(0xFFE1E2E9);
  static const Color strokeLight = Color(0xFFEDEEF4);

  // BG
  static const Color bgBlack = Color(0xFF1A2022);
  static const Color bgDarkGrey = Color(0xFF343839);
  static const Color bgGray = Color(0xFFF5F5F5);
  static const Color bgLightGray = Color(0xFFFAFAFA);
  static const Color bgWhite = Color(0xFFFFFFFF);

  // Text
  static const Color textBlack = Color(0xFF0A121A);
  static const Color textDarkGrey = Color(0xFF5C6068);
  static const Color textGrey = Color(0xFF8D8F9F);
  static const Color textLightGray = Color(0xFFD0D1DA);

  // Tons derivados (não estão no Figma, servem só de fundo suave)
  static const Color tealSoft = Color(0xFFE0F2F1);
  static const Color orangeSoft = Color(0xFFFFF0EA);
  static const Color pinkSoft = Color(0xFFFDEAF1);
}

/// Escala tipográfica do CP4 (Figma "CP1" > font). Títulos e textos em Poppins;
/// valores em reais usam Inter com algarismos tabulares (README do CP1).
class AppText {
  AppText._();

  static TextStyle _poppins(double size, FontWeight weight, {double? height}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: AppColors.textBlack,
      );

  static TextStyle get h2 => _poppins(28, FontWeight.w700, height: 34 / 28);
  static TextStyle get h3 => _poppins(24, FontWeight.w700, height: 1.2);
  static TextStyle get h4 => _poppins(18, FontWeight.w700, height: 1.25);
  static TextStyle get h5 => _poppins(16, FontWeight.w700, height: 1.25);
  static TextStyle get h6 => _poppins(14, FontWeight.w700, height: 1.3);
  static TextStyle get body1 => _poppins(16, FontWeight.w300, height: 24 / 16);
  static TextStyle get body2 => _poppins(14, FontWeight.w300, height: 1.45);
  static TextStyle get button => _poppins(14, FontWeight.w500);
  static TextStyle get label => _poppins(12, FontWeight.w700, height: 1.3);
  static TextStyle get caption =>
      _poppins(12, FontWeight.w400, height: 1.35).copyWith(color: AppColors.textDarkGrey);

  /// Preços: Inter + algarismos tabulares para alinhar os valores.
  static TextStyle price({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textBlack,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class AppTheme {
  AppTheme._();

  // Mantidos por compatibilidade com o código do CP4.
  static const Color primary = AppColors.orange;
  static const Color secondary = AppColors.teal;
  static const Color tertiary = AppColors.tertiary;
  static const Color buttonHover = AppColors.buttonHover;
  static const Color buttonDisabled = AppColors.buttonDisabled;
  static const Color background = AppColors.bgGray;

  static const double radius = 16;
  static const double radiusSmall = 12;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.bgBlack.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      displaySmall: AppText.h2,
      headlineMedium: AppText.h3,
      headlineSmall: AppText.h4,
      titleLarge: AppText.h4,
      titleMedium: AppText.h5,
      titleSmall: AppText.h6,
      bodyLarge: AppText.body1,
      bodyMedium: AppText.body2,
      bodySmall: AppText.caption,
      labelLarge: AppText.button,
      labelMedium: AppText.label,
      labelSmall: AppText.label.copyWith(fontSize: 11),
    );

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.buttonDisabled;
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
          return AppColors.buttonHover;
        }
        return AppColors.buttonDefault;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return Colors.white70;
        return Colors.white;
      }),
      textStyle: WidgetStatePropertyAll(AppText.button.copyWith(fontSize: 15)),
      minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.orange,
      scaffoldBackgroundColor: AppColors.bgGray,
      colorScheme: const ColorScheme.light(
        primary: AppColors.orange,
        onPrimary: Colors.white,
        secondary: AppColors.teal,
        onSecondary: Colors.white,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        surface: AppColors.bgWhite,
        onSurface: AppColors.textBlack,
        outline: AppColors.strokeGrey,
        outlineVariant: AppColors.strokeLight,
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgWhite,
        foregroundColor: AppColors.textBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppText.h5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: AppColors.orange, width: 1.4),
          textStyle: AppText.button.copyWith(fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orange,
          textStyle: AppText.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgWhite,
        hintStyle: AppText.body2.copyWith(color: AppColors.textGrey),
        labelStyle: AppText.body2.copyWith(color: AppColors.textDarkGrey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.strokeGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.strokeGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgWhite,
        selectedColor: AppColors.orangeSoft,
        side: const BorderSide(color: AppColors.strokeGrey),
        labelStyle: AppText.caption.copyWith(color: AppColors.textBlack),
        iconTheme: const IconThemeData(color: AppColors.orange, size: 16),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.strokeLight),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.strokeLight, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgWhite,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.orangeSoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppText.label.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.orange : AppColors.textGrey,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.orange : AppColors.textGrey);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.orange,
        unselectedLabelColor: AppColors.textGrey,
        indicatorColor: AppColors.orange,
        labelStyle: AppText.h6,
        unselectedLabelStyle: AppText.h6.copyWith(fontWeight: FontWeight.w500),
        dividerColor: AppColors.strokeLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgBlack,
        contentTextStyle: AppText.body2.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgWhite,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
