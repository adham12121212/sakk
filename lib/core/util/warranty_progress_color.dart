import 'dart:ui';

import '../constant/app_colors.dart';

/// Colour for a warranty progress ring, from the share of the warranty left
/// (0.0–1.0), like a battery: green from 50%, amber from 20%, red below.
/// Used by the Details header ring and the product list rings.
Color warrantyProgressColor(double remaining) {
  if (remaining >= 0.5) return AppColors.success;
  if (remaining >= 0.2) return const Color(0xFFF59E0B);
  return AppColors.error;
}
