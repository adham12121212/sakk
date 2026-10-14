import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/core/widgets/app_skeleton_config.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The shimmer a Skeletonizer under [AppSkeletonConfig] actually uses, with
/// the app on [themeMode] and the phone on [phone].
Future<ShimmerEffect> effectFor(WidgetTester tester, {required ThemeMode themeMode, required Brightness phone}) async {
  tester.platformDispatcher.platformBrightnessTestValue = phone;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  late BuildContext inside;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    builder: (context, child) => AppSkeletonConfig(child: child!),
    home: Skeletonizer(
      enabled: true,
      child: Builder(builder: (context) {
        inside = context;
        return const Text('Loading');
      }),
    ),
  ));
  // Let a theme change finish animating (not pumpAndSettle: the shimmer
  // loops forever).
  await tester.pump(const Duration(milliseconds: 500));
  return Skeletonizer.of(inside).config.effect as ShimmerEffect;
}

void main() {
  const light = ShimmerEffect();
  const dark = ShimmerEffect.dark();

  testWidgets('app in Light on a phone in dark mode: light skeletons', (tester) async {
    expect(await effectFor(tester, themeMode: ThemeMode.light, phone: Brightness.dark), light);
  });

  testWidgets('app in Dark on a phone in light mode: dark skeletons', (tester) async {
    expect(await effectFor(tester, themeMode: ThemeMode.dark, phone: Brightness.light), dark);
  });

  testWidgets('app on Auto follows the phone', (tester) async {
    expect(await effectFor(tester, themeMode: ThemeMode.system, phone: Brightness.dark), dark);
    expect(await effectFor(tester, themeMode: ThemeMode.system, phone: Brightness.light), light);
  });

  test('the light and dark skeletons really differ', () {
    expect(light, isNot(dark));
  });
}
