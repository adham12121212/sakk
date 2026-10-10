import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

/// Design tokens that Material's ColorScheme has no slot for: warranty-status
/// colours (each with a soft background for chips/banners) and the soft card
/// shadow. Registered as a ThemeExtension, so it switches with light/dark.
///
/// Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.cardShadow,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;

  /// Soft, wide shadow for cards on the off-white background. Empty in dark
  /// mode, where cards are separated by their lighter surface and a hairline.
  final List<BoxShadow> cardShadow;

  static const light = AppPalette(
    success: Color(0xFF16A34A),
    successContainer: Color(0xFFE8F7EE),
    warning: Color(0xFFD97706),
    warningContainer: Color(0xFFFFF4E0),
    danger: AppColors.error,
    dangerContainer: Color(0xFFFDECEC),
    cardShadow: [
      BoxShadow(color: Color(0x0F0F172A), blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x050F172A), blurRadius: 4, offset: Offset(0, 1)),
    ],
  );

  static const dark = AppPalette(
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF143222),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF3A2D10),
    danger: Color(0xFFF87171),
    dangerContainer: Color(0xFF3B1A1A),
    cardShadow: [],
  );

  @override
  AppPalette copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    List<BoxShadow>? cardShadow,
  }) {
    return AppPalette(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
