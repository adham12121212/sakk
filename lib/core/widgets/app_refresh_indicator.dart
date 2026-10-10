import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant/app_colors.dart';
import 'sakk_logo.dart';

/// Branded pull-to-refresh: pulling slides the content down and reveals a
/// round badge with the صك logo whose outer ring fills toward the trigger
/// point; a light haptic tap marks the point, and the ring spins while
/// [onRefresh] runs. Drop-in replacement for [RefreshIndicator].
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Pull distance (logical px) needed to trigger a refresh.
  static const double _armedOffset = 96;

  /// How far the content slides down at the trigger point / while loading.
  static const double _contentShift = 76;

  static const double _badgeSize = 48;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: _armedOffset,
      // Vertical, top-level scrolling only: horizontal lists inside the page
      // (e.g. filter chips) must not start a refresh.
      notificationPredicate: (notification) =>
          notification.depth == 0 && notification.metrics.axis == Axis.vertical,
      onStateChanged: (change) {
        if (change.didChange(to: IndicatorState.armed)) {
          HapticFeedback.lightImpact();
        }
      },
      builder: (context, child, controller) {
        // value runs 0 → 1 at the trigger point (and can overshoot); it sits
        // at 1 while loading and animates back to 0 when done.
        final pull = controller.value.clamp(0.0, 1.0);
        final shift = pull * _contentShift;

        return Stack(
          children: [
            Transform.translate(offset: Offset(0, shift), child: child),
            if (!controller.isIdle)
              Positioned(
                top: (shift - _badgeSize) / 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: pull,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * pull,
                      child: _RefreshBadge(
                        size: _badgeSize,
                        progress: controller.isLoading ? null : pull,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Surface-coloured circle with the logo, wrapped in a progress ring that is
/// determinate while pulling ([progress]) and spins while loading (null).
class _RefreshBadge extends StatelessWidget {
  const _RefreshBadge({required this.size, required this.progress});

  final double size;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size - 4,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          SakkLogo(size: size - 4, color: AppColors.primary),
        ],
      ),
    );
  }
}
