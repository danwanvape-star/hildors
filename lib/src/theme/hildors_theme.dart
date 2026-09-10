import 'package:flutter/material.dart';

abstract final class HildorsColors {
  static const background = Color(0xFF05080D);
  static const backgroundRaised = Color(0xFF080D14);
  static const surface = Color(0xFF0D131C);
  static const surfaceElevated = Color(0xFF141C27);
  static const surfaceHighlight = Color(0xFF1B2635);
  static const purple = Color(0xFF7457D7);
  static const purpleBright = Color(0xFFA77BFF);
  static const teal = Color(0xFF34E7D4);
  static const blue = Color(0xFF65B8FF);
  static const gold = Color(0xFFE4C58B);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAEBAC8);
  static const hairline = Color(0xFF263445);
}

ThemeData buildHildorsTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: HildorsColors.teal,
    brightness: Brightness.dark,
  ).copyWith(
    primary: HildorsColors.teal,
    onPrimary: HildorsColors.background,
    primaryContainer: const Color(0xFF123B3B),
    onPrimaryContainer: const Color(0xFFD9FFFB),
    secondary: HildorsColors.blue,
    onSecondary: HildorsColors.background,
    secondaryContainer: const Color(0xFF132D46),
    onSecondaryContainer: const Color(0xFFE0F2FF),
    tertiary: HildorsColors.purpleBright,
    onTertiary: HildorsColors.background,
    surface: HildorsColors.surface,
    onSurface: HildorsColors.textPrimary,
    onSurfaceVariant: HildorsColors.textSecondary,
    surfaceContainerLowest: HildorsColors.background,
    surfaceContainerLow: HildorsColors.surface,
    surfaceContainer: HildorsColors.surfaceElevated,
    surfaceContainerHigh: HildorsColors.surfaceHighlight,
    outline: HildorsColors.hairline,
    outlineVariant: const Color(0xFF182331),
  );

  const rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    colorScheme: scheme,
    scaffoldBackgroundColor: HildorsColors.background,
    canvasColor: HildorsColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: HildorsColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: HildorsColors.textPrimary,
        fontFamily: 'Poppins',
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xE6121923),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: HildorsColors.teal.withValues(alpha: 0.14),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: HildorsColors.teal.withValues(alpha: 0.25),
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? HildorsColors.teal
              : HildorsColors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? HildorsColors.textPrimary
              : HildorsColors.textSecondary,
          fontSize: 11,
          letterSpacing: 0.4,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HildorsColors.teal,
        foregroundColor: HildorsColors.background,
        elevation: 0,
        shape: rounded,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HildorsColors.teal,
        side: const BorderSide(color: HildorsColors.teal),
        shape: rounded,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xD9141C27),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: HildorsColors.teal),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: HildorsColors.surfaceElevated,
      selectedColor: HildorsColors.teal.withValues(alpha: 0.18),
      side: const BorderSide(color: Color(0xFF453B4A)),
      shape: const StadiumBorder(),
    ),
    dividerColor: const Color(0xFF342F37),
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      bodySmall: TextStyle(
        color: HildorsColors.textSecondary,
        fontSize: 12,
        height: 1.4,
      ),
    ),
  );
}
