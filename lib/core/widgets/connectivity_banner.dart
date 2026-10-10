import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../constant/app_colors.dart';
import '../error/network_info.dart';
import '../theme/app_icons.dart';

/// App-wide connection strip, placed in `MaterialApp.builder` so it shows
/// above every screen. Offline: a dark strip "You're offline. Showing saved
/// data." that stays until the connection returns. Back online: it turns
/// green ("Back online") for a moment, then slides away, and
/// [onReconnected] runs so screens can reload.
///
/// While the strip is visible it takes the top safe area itself and removes
/// that padding for the app below, so screens don't add it a second time.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({
    super.key,
    required this.networkInfo,
    required this.child,
    this.onReconnected,
    this.suppressed = false,
  });

  final NetworkInfo networkInfo;
  final Widget child;
  final VoidCallback? onReconnected;

  /// Keeps the strip hidden (e.g. on the splash screen, so it can't push the
  /// logo away from where the native splash put it). Status is still tracked.
  final bool suppressed;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

enum _BannerState { hidden, offline, backOnline }

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  static const _backOnlineVisibleFor = Duration(seconds: 2);

  StreamSubscription<bool>? _subscription;
  Timer? _hideTimer;
  _BannerState _state = _BannerState.hidden;

  @override
  void initState() {
    super.initState();
    _subscription = widget.networkInfo.onConnectivityChanged.listen(_onConnectivity);
  }

  void _onConnectivity(bool connected) {
    _hideTimer?.cancel();
    if (!connected) {
      setState(() => _state = _BannerState.offline);
      return;
    }
    // Only celebrate a reconnect, not the first "connected" at app start.
    if (_state != _BannerState.offline) return;
    setState(() => _state = _BannerState.backOnline);
    widget.onReconnected?.call();
    _hideTimer = Timer(_backOnlineVisibleFor, () {
      if (mounted) setState(() => _state = _BannerState.hidden);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _state != _BannerState.hidden && !widget.suppressed;
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: visible
              ? _Strip(offline: _state == _BannerState.offline, topInset: topInset)
              : const SizedBox(width: double.infinity),
        ),
        // Same widget either way: swapping the wrapper in and out would
        // rebuild the app's Router from scratch, losing the open screens
        // (and the arguments they were opened with).
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: visible, child: widget.child),
        ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.offline, required this.topInset});

  final bool offline;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final background = offline ? const Color(0xFF1F2937) : AppColors.success;
    final label = offline ? l10n.offlineBanner : l10n.backOnlineBanner;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons on the dark/green strip.
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: background,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16, topInset + 6, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  offline ? AppIcons.offline : AppIcons.online,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
