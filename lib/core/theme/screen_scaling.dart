import 'dart:math';

import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Whether `.w`, `.h`, `.r` and `.sp` scale from the 390x844 phone design.
///
/// Off on tablets and unfolded foldables (shortest side of 600dp or more),
/// where they mean plain dp. Scaling there would triple everything by width
/// and overflow the screen. Android also ignores the app's portrait lock on
/// these screens, so they can really be in landscape.
bool scalesWithScreen() {
  final screen = ScreenUtil();
  return min(screen.screenWidth, screen.screenHeight) < 600;
}
