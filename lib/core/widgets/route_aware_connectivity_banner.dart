import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../error/network_info.dart';
import 'connectivity_banner.dart';

/// [ConnectivityBanner] that hides itself on some routes (the splash screen).
///
/// The router reports route changes while widgets are still being built, at
/// launch even before the first frame, so the rebuild always waits for the
/// end of the current frame; rebuilding right away throws "setState() or
/// markNeedsBuild() called during build".
class RouteAwareConnectivityBanner extends StatefulWidget {
  const RouteAwareConnectivityBanner({
    super.key,
    required this.routerDelegate,
    required this.isSuppressed,
    required this.networkInfo,
    required this.child,
    this.onReconnected,
  });

  final Listenable routerDelegate;
  final bool Function() isSuppressed;
  final NetworkInfo networkInfo;
  final VoidCallback? onReconnected;
  final Widget child;

  @override
  State<RouteAwareConnectivityBanner> createState() => _RouteAwareConnectivityBannerState();
}

class _RouteAwareConnectivityBannerState extends State<RouteAwareConnectivityBanner> {
  late bool _suppressed = widget.isSuppressed();
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    widget.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted) return;
      final suppressed = widget.isSuppressed();
      if (suppressed != _suppressed) setState(() => _suppressed = suppressed);
    });
    // Make sure a frame comes, so the callback runs even if nothing else
    // asked for one.
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      networkInfo: widget.networkInfo,
      onReconnected: widget.onReconnected,
      suppressed: _suppressed,
      child: widget.child,
    );
  }
}
