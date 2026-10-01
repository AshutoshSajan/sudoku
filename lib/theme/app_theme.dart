import 'package:flutter/material.dart';

/// Application-wide theme definitions with light and dark variants.
class AppTheme {
  AppTheme._();

  static const _primarySeed = Color(0xFF5C6BC0); // Indigo 400

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F6FC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D0D1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1A1A2E),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

/// Board-specific color tokens resolved from the current theme.
class BoardColors {
  final Color background;
  final Color cellBorder;
  final Color boxBorder;
  final Color selectedCell;
  final Color highlightedCell;
  final Color sameNumberCell;
  final Color errorCell;
  final Color givenText;
  final Color userText;
  final Color errorText;
  final Color notesText;

  const BoardColors._({
    required this.background,
    required this.cellBorder,
    required this.boxBorder,
    required this.selectedCell,
    required this.highlightedCell,
    required this.sameNumberCell,
    required this.errorCell,
    required this.givenText,
    required this.userText,
    required this.errorText,
    required this.notesText,
  });

  factory BoardColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    if (isDark) {
      return BoardColors._(
        background: const Color(0xFF1A1A2E),
        cellBorder: const Color(0xFF2A2A3A),
        boxBorder: const Color(0xFF6A6A7A),
        selectedCell: primary.withAlpha(64),
        highlightedCell: primary.withAlpha(20),
        sameNumberCell: primary.withAlpha(46),
        errorCell: const Color(0xFFE53935).withAlpha(46),
        givenText: const Color(0xFFE0E0EC),
        userText: primary,
        errorText: const Color(0xFFEF9A9A),
        notesText: const Color(0xFF9E9E9E),
      );
    } else {
      return BoardColors._(
        background: Colors.white,
        cellBorder: const Color(0xFFD4D4D4),
        boxBorder: const Color(0xFF333333),
        selectedCell: primary.withAlpha(51),
        highlightedCell: primary.withAlpha(15),
        sameNumberCell: primary.withAlpha(36),
        errorCell: const Color(0xFFE53935).withAlpha(30),
        givenText: const Color(0xFF1A1A2E),
        userText: primary,
        errorText: const Color(0xFFE53935),
        notesText: const Color(0xFF757575),
      );
    }
  }
}
