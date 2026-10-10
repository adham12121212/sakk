import 'package:flutter/widgets.dart';

import '../theme/app_palette.dart';

/// Colour for a warranty progress ring, from the share of the warranty left
/// (0.0–1.0), like a battery: green from 50%, amber from 20%, red below.
/// Used by the Details header ring and the product list rings.
Color warrantyProgressColor(BuildContext context, double remaining) {
  final palette = context.palette;
  if (remaining >= 0.5) return palette.success;
  if (remaining >= 0.2) return palette.warning;
  return palette.danger;
}
