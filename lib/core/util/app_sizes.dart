import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standard sizes used across the app.
///
/// Avoid hardcoding values like:
/// 8, 12, 16, 20, 24...
///
/// Instead use:
/// AppSizes.s16
/// AppSizes.icon24
/// AppSizes.buttonHeight
class AppSizes {
  AppSizes._();

  // Padding / Margin
  static double get s2 => 2.w;
  static double get s4 => 4.w;
  static double get s6 => 6.w;
  static double get s8 => 8.w;
  static double get s10 => 10.w;
  static double get s12 => 12.w;
  static double get s14 => 14.w;
  static double get s16 => 16.w;
  static double get s18 => 18.w;
  static double get s20 => 20.w;
  static double get s24 => 24.w;
  static double get s28 => 28.w;
  static double get s32 => 32.w;
  static double get s40 => 40.w;
  static double get s48 => 48.w;
  static double get s56 => 56.w;
  static double get s64 => 64.w;

  // Icon Sizes
  static double get icon16 => 16.sp;
  static double get icon18 => 18.sp;
  static double get icon20 => 20.sp;
  static double get icon22 => 22.sp;
  static double get icon24 => 24.sp;
  static double get icon28 => 28.sp;
  static double get icon32 => 32.sp;

  // Buttons
  static double get buttonHeight => 54.h;
  static double get smallButtonHeight => 46.h;

  // TextFields
  static double get textFieldHeight => 56.h;

  // Avatar
  static double get avatarSmall => 40.w;
  static double get avatarMedium => 56.w;
  static double get avatarLarge => 72.w;

  // Header
  static double get headerHeight => 240.h;

  // Bottom Navigation
  static double get bottomNavHeight => 72.h;
}