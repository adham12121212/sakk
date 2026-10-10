import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../l10n/app_localizations.dart';

class ScanFailedView extends StatelessWidget {
  const ScanFailedView({
    super.key,
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88.w,
                  height: 88.w,
                  decoration: BoxDecoration(
                    color: context.palette.dangerContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: context.palette.danger, size: 40.sp),
                ),
                SizedBox(height: 20.h),
                Text(
                  l10n.couldNotReadReceipt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8.h),
                Text(
                  userFacingError(l10n, message),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: onBack,
                    child: Text(l10n.tryAnotherPhoto),
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