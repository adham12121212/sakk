import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tablets and unfolded foldables have a shortest side of at least this (dp).
const tabletShortestSide = 600.0;

/// Whether `.w`, `.h`, `.r` and `.sp` scale from the 390x844 phone design.
///
/// Off on tablets and unfolded foldables ([tabletShortestSide] or more),
/// where they mean plain dp. Scaling there would triple everything by width
/// and overflow the screen. Android also ignores the app's portrait lock on
/// these screens, so they can really be in landscape.
bool scalesWithScreen() {
  final screen = ScreenUtil();
  return min(screen.screenWidth, screen.screenHeight) < tabletShortestSide;
}

/// Whether this screen gets the tablet layout: side rail and centred content.
bool isTabletLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= tabletShortestSide;
