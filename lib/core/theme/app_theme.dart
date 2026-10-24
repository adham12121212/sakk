import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant/app_colors.dart';
import 'app_palette.dart';

/// Light/dark ThemeData for the "soft & airy" look: an off-white page
/// background with white cards on top (soft shadows in light mode, layered
/// greys in dark mode), slate-tinted text, a single type scale and rounded
/// component themes. Screens should read colours from
/// `Theme.of(context).colorScheme`, text styles from `.textTheme`, and status
/// colours / card shadows from `context.palette` ([AppPalette]).
///
/// Token map:
///   page background        -> scaffoldBackgroundColor (light #F6F7FB)
///   cards, sheets, tiles   -> colorScheme.surface (white / #1A1D23)
///   fields, chips, wells   -> colorScheme.surfaceContainerHighest
///   hairlines, borders     -> colorScheme.outline
///   primary text           -> colorScheme.onSurface
///   secondary text         -> colorScheme.onSurfaceVariant
class AppTheme {
  AppTheme._();

  static ThemeData light() => _themeFor(Brightness.light);
  static ThemeData dark() => _themeFor(Brightness.dark);

  /// Transparent status and navigation bars with icons that read on the
  /// page, so the app draws edge to edge: no black strip under Android's
  /// gesture bar, and the bottom menu's white reaches the screen's edge.
  static SystemUiOverlayStyle systemBars(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static const double radiusCard = 20;
  static const double radiusControl = 16;

  static ThemeData _themeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF1E2A4A)
          : const Color(0xFFE8F0FE),
      onPrimaryContainer: isDark
          ? const Color(0xFFBFD3FF)
          : const Color(0xFF1546B0),
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? const Color(0xFF1A1D23) : Colors.white,
      onSurface: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      onSurfaceVariant: isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF64748B),
      surfaceContainerHighest: isDark
          ? const Color(0xFF262A31)
          : const Color(0xFFF1F4F9),
      surfaceContainerHigh: isDark
          ? const Color(0xFF22262C)
          : const Color(0xFFF5F7FB),
      surfaceContainer: isDark
          ? const Color(0xFF1E2127)
          : const Color(0xFFF8FAFC),
      surfaceContainerLow: isDark
          ? const Color(0xFF181B20)
          : const Color(0xFFFBFCFE),
      surfaceContainerLowest: isDark ? const Color(0xFF13161A) : Colors.white,
      outline: isDark ? const Color(0xFF2E333B) : const Color(0xFFE6E9F0),
      outlineVariant: isDark
          ? const Color(0xFF262A31)
          : const Color(0xFFF0F2F6),
      shadow: Colors.black,
    );

    final background = isDark
        ? const Color(0xFF0F1115)
        : const Color(0xFFF6F7FB);
    final textTheme = GoogleFonts.cairoTextTheme(_textTheme(colorScheme));

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusControl),
    );
    // Derived from the text theme so buttons keep the Cairo family (a bare
    // TextStyle here would fall back to the system font).
    final buttonTextStyle = textTheme.labelLarge!.copyWith(fontSize: 15);

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [palette],
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outline,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: colorScheme.onSurface),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: systemBars(brightness),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: isDark
              ? BorderSide(color: colorScheme.outline)
              : BorderSide.none,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: controlShape,
          textStyle: buttonTextStyle,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: controlShape,
          textStyle: buttonTextStyle,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 52),
          shape: controlShape,
          side: BorderSide(color: colorScheme.outline, width: 1.2),
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: controlShape,
          textStyle: buttonTextStyle,
        ),
      ),

      // Light: white fields with a hairline on the off-white page (a grey
      // fill would almost vanish there). Dark: filled, which already contrasts.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: colorScheme.outline, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: AppColors.primary,
        side: BorderSide(color: colorScheme.outline),
        shape: const StadiumBorder(),
        // White on the brand colour once selected; grey while not.
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => textTheme.labelLarge!.copyWith(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : colorScheme.onSurfaceVariant,
          ),
        ),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF2A2F37)
            : const Color(0xFF1E293B),
        contentTextStyle: textTheme.bodyMedium!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.transparent : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2F37) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall!.copyWith(color: Colors.white),
      ),
    );
  }

  /// One type scale for the whole app. Sizes are logical pixels.
  static TextTheme _textTheme(ColorScheme scheme) {
    final strong = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    TextStyle s(
      double size,
      FontWeight weight,
      Color color, {
      double height = 1.3,
      double spacing = 0,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

    return TextTheme(
      displayLarge: s(40, FontWeight.w800, strong, height: 1.15, spacing: -0.8),
      displayMedium: s(
        34,
        FontWeight.w800,
        strong,
        height: 1.15,
        spacing: -0.6,
      ),
      displaySmall: s(30, FontWeight.w700, strong, height: 1.2, spacing: -0.5),
      headlineLarge: s(28, FontWeight.w700, strong, height: 1.2, spacing: -0.4),
      headlineMedium: s(
        26,
        FontWeight.w700,
        strong,
        height: 1.2,
        spacing: -0.3,
      ),
      headlineSmall: s(
        22,
        FontWeight.w700,
        strong,
        height: 1.25,
        spacing: -0.2,
      ),
      titleLarge: s(18, FontWeight.w700, strong),
      titleMedium: s(16, FontWeight.w600, strong),
      titleSmall: s(14, FontWeight.w600, strong),
      bodyLarge: s(16, FontWeight.w400, strong, height: 1.5),
      bodyMedium: s(14, FontWeight.w400, strong, height: 1.45),
      bodySmall: s(12, FontWeight.w400, muted, height: 1.4),
      labelLarge: s(14, FontWeight.w600, strong),
      labelMedium: s(12, FontWeight.w600, muted),
      labelSmall: s(11, FontWeight.w600, muted, spacing: 0.2),
    );
  }
}
