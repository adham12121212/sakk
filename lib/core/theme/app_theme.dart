import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant/app_colors.dart';

/// Central place for light/dark ThemeData. The goal: every screen should
/// stop hardcoding AppColors.white / AppColors.black / Colors.grey.shadeXXX
/// directly, and instead pull from Theme.of(context).colorScheme /
/// .textTheme — so backgrounds AND text correctly invert together per
/// theme, instead of drifting out of sync (which is what caused text to
/// go invisible: unstyled Text inherited dark-mode's near-white default
/// while its container stayed hardcoded white).
///
/// Semantic token cheat-sheet (see each screen's conversion):
///   AppColors.white            -> colorScheme.surface
///   AppColors.black            -> colorScheme.onSurface
///   Colors.grey.shade600       -> colorScheme.onSurface.withOpacity(0.6)
///   Colors.grey.shade200       -> colorScheme.outline
///   Colors.grey.shade100       -> colorScheme.surfaceContainerHighest
///   AppColors.error            -> colorScheme.error
///   AppColors.primary          -> colorScheme.primary (unchanged either theme)
class AppTheme {
  AppTheme._();

  static ThemeData light() => _themeFor(Brightness.light);
  static ThemeData dark() => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      onSurface: isDark ? Colors.white : AppColors.black,
      // Light values must be visibly different from the white surface: these
      // back chips, fields and chat bubbles (fill) and card borders (outline).
      surfaceContainerHighest:
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
      outline: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      // Cairo isn't bundled as an asset; google_fonts fetches it once and
      // caches it on the device.
      fontFamily: GoogleFonts.cairo().fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      dividerColor: colorScheme.outline,
      cardColor: colorScheme.surface,
      textTheme: GoogleFonts.cairoTextTheme(_textTheme(colorScheme)),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final primary = TextStyle(color: scheme.onSurface);
    final secondary = TextStyle(color: scheme.onSurface.withOpacity(0.6));

    return TextTheme(
      displayLarge: primary,
      displayMedium: primary,
      displaySmall: primary,
      headlineLarge: primary,
      headlineMedium: primary,
      headlineSmall: primary,
      titleLarge: primary,
      titleMedium: primary,
      titleSmall: primary,
      bodyLarge: primary,
      bodyMedium: primary,
      bodySmall: secondary,
      labelLarge: primary,
      labelMedium: secondary,
      labelSmall: secondary,
    );
  }
}