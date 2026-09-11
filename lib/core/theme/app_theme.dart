import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF1B2A5B);
  static const navyDeep = Color(0xFF16234B);
  static const danger = Color(0xFFD1425A);
  static const accent = Color(0xFFC98A12);

  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    ).copyWith(primary: navy, error: danger),
    const Color(0xFFFDFDFD),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.dark,
    ).copyWith(error: danger),
    const Color(0xFF12151F),
  );

  static ThemeData _build(ColorScheme scheme, Color background) {
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isLight ? navyDeep : scheme.primary,
          foregroundColor: isLight ? Colors.white : scheme.onPrimary,
          disabledBackgroundColor: (isLight ? navyDeep : scheme.primary).withValues(
            alpha: 0.5,
          ),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF6F7FB) : const Color(0xFF1C2130),
        border: _border(scheme.outlineVariant),
        enabledBorder: _border(scheme.outlineVariant),
        focusedBorder: _border(scheme.primary, width: 1.6),
        errorBorder: _border(danger),
        focusedErrorBorder: _border(danger, width: 1.6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
