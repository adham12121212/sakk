import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../l10n/app_localizations.dart';
import '../constant/app_colors.dart';
import '../error/Failure.dart';

/// Shared error state: tinted icon, short title, one-line explanation and a
/// "Try again" button. Picks the offline or the generic wording from the
/// failure [message] (raw repository text is never shown; it's logged where
/// it happens).
///
/// [onRetry] may be async: the button shows a spinner and ignores taps until
/// it completes. Pass [actionLabel]/[actionIcon] to use the button for
/// something else (e.g. "Back").
///
/// With [fillRemaining], the view takes the remaining height, centres itself
/// and stays scrollable, so a surrounding pull-to-refresh still works.
class AppErrorView extends StatefulWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.actionLabel,
    this.actionIcon,
    this.fillRemaining = false,
  });

  final String? message;
  final Future<void> Function()? onRetry;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool fillRemaining;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _retrying = false;

  bool get _isOffline => widget.message == NetworkFailure.noConnectionMessage;

  Future<void> _retry() async {
    final onRetry = widget.onRetry;
    if (onRetry == null || _retrying) return;
    setState(() => _retrying = true);
    try {
      await onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    if (!widget.fillRemaining) return content;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _isOffline ? AppColors.primary : AppColors.error;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                size: 40.sp,
                color: accent,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              _isOffline ? l10n.errorOfflineTitle : l10n.errorGenericTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _isOffline ? l10n.errorOfflineBody : l10n.errorGenericBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (widget.onRetry != null) ...[
              SizedBox(height: 24.h),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _retrying ? null : _retry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    shape: const StadiumBorder(),
                  ),
                  icon: _retrying
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(widget.actionIcon ?? Icons.refresh_rounded, color: Colors.white),
                  label: Text(
                    widget.actionLabel ?? l10n.tryAgain,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
