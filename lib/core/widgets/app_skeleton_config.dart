import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Makes every loading skeleton below follow the app's theme (Light, Dark or
/// Auto in Profile). Without it, skeletonizer follows the phone's setting, so
/// the app in Light on a phone in dark mode got dark grey skeletons.
class AppSkeletonConfig extends StatelessWidget {
  const AppSkeletonConfig({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SkeletonizerConfig(
      data: SkeletonizerConfigData(brightness: Theme.of(context).brightness),
      child: child,
    );
  }
}
