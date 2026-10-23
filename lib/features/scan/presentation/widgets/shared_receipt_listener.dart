import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/service/share_intake.dart';

/// Opens Scan with a receipt shared to Sakk from another app, once a
/// signed-in screen is showing. A share that launched the app waits through
/// the splash, sign-in and lock screens; one that arrives while the app is
/// open is scanned straight away.
class SharedReceiptListener extends StatefulWidget {
  const SharedReceiptListener({
    super.key,
    required this.router,
    required this.intake,
    required this.child,
  });

  final GoRouter router;
  final ShareIntake intake;
  final Widget child;

  /// Screens before the user is signed in and unlocked, or that don't
  /// belong to a session (the legal pages).
  static const waitingRoutes = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.signin,
    AppRoutes.signup,
    AppRoutes.forgotPassword,
    AppRoutes.biometricLock,
    AppRoutes.terms,
    AppRoutes.privacy,
  };

  @override
  State<SharedReceiptListener> createState() => _SharedReceiptListenerState();
}

class _SharedReceiptListenerState extends State<SharedReceiptListener> {
  @override
  void initState() {
    super.initState();
    widget.intake.pending.addListener(_maybeOpen);
    widget.router.routerDelegate.addListener(_maybeOpen);
    _maybeOpen();
  }

  // After the frame: the router may still be mid-navigation when it
  // notifies, and the first frame has no route yet.
  void _maybeOpen() {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _open())
      ..scheduleFrame();
  }

  void _open() {
    if (!mounted || widget.intake.pending.value == null) return;
    final path = widget.router.routerDelegate.currentConfiguration.uri.path;
    if (path.isEmpty || SharedReceiptListener.waitingRoutes.contains(path)) {
      return;
    }
    final receipt = widget.intake.take();
    if (receipt != null) widget.router.push(AppRoutes.scan, extra: receipt);
  }

  @override
  void dispose() {
    widget.intake.pending.removeListener(_maybeOpen);
    widget.router.routerDelegate.removeListener(_maybeOpen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
