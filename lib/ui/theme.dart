import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFD6737);
  static const Color secondary = Color(0xFF009688);
  static const Color tertiary = Color(0xFFE91E63);
  static const Color buttonHover = Color(0xFFD73E1C);
  static const Color buttonDisabled = Color(0xFFB3B3B3);
  static const Color background = Color(0xFFF5F5F7);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return buttonDisabled;
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return buttonHover;
            }
            return primary; // Cor padrão
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white70;
            }
            return Colors.white;
          }),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ),
    );
  }
}
