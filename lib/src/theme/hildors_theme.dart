import 'package:flutter/material.dart';

abstract final class HildorsColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF121212);
  static const surfaceElevated = Color(0xFF1E1E1E);
  static const purple = Color(0xFF9B66D7);
  static const purpleBright = Color(0xFF9C54EF);
  static const teal = Color(0xFF01CABF);
  static const blue = Color(0xFF4BA8EB);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFC9C3CF);
}

ThemeData buildHildorsTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: HildorsColors.teal,
    brightness: Brightness.dark,
  ).copyWith(
    primary: HildorsColors.teal,
    onPrimary: HildorsColors.background,
    primaryContainer: const Color(0xFF073B38),
    onPrimaryContainer: const Color(0xFFD9FFFB),
    secondary: HildorsColors.blue,
    onSecondary: HildorsColors.background,
    secondaryContainer: const Color(0xFF073B38),
    onSecondaryContainer: const Color(0xFFD9FFFB),
    tertiary: HildorsColors.purpleBright,
    onTertiary: HildorsColors.background,
    surface: HildorsColors.surface,
    onSurface: HildorsColors.textPrimary,
    onSurfaceVariant: HildorsColors.textSecondary,
    outline: const Color(0xFF665E6B),
  );

  const rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    colorScheme: scheme,
    scaffoldBackgroundColor: HildorsColors.background,
    canvasColor: HildorsColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: HildorsColors.background,
      foregroundColor: HildorsColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: HildorsColors.surfaceElevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: HildorsColors.surface,
      indicatorColor: HildorsColors.teal.withValues(alpha: 0.18),
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
          fontSize: 12,
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
      fillColor: HildorsColors.surfaceElevated,
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
  );
}
