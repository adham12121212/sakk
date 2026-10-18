import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/route/app_router.dart';
import '../../domain/pro_limit.dart';

/// Opens the paywall whenever the server refuses something for the free
/// plan's limits ([ProLimit.events]), from wherever it happened: a scan, a
/// chat message or saving a product, subscription or installment plan. The
/// screen that failed still shows its own error message under it.
class ProLimitListener extends StatefulWidget {
  const ProLimitListener({super.key, required this.router, required this.child, this.events});

  final GoRouter router;
  final Widget child;

  /// For tests; [ProLimit.events] by default.
  final Stream<PaywallReason>? events;

  @override
  State<ProLimitListener> createState() => _ProLimitListenerState();
}

class _ProLimitListenerState extends State<ProLimitListener> {
  late final StreamSubscription<PaywallReason> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = (widget.events ?? ProLimit.events).listen(_open);
  }

  void _open(PaywallReason reason) {
    final router = widget.router;
    // Already on the paywall (e.g. two refusals in a row): don't stack another.
    if (router.routerDelegate.currentConfiguration.uri.path == AppRoutes.paywall) return;
    router.push(AppRoutes.paywall, extra: reason);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
