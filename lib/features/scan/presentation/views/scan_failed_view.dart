import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constant/app_colors.dart';
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: const Color(0xFFE05757),
                    size: 34.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  l10n.couldNotReadReceipt,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black54, height: 1.4),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: FilledButton(
                    onPressed: onBack,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
                      backgroundColor: AppColors.primary,
                    ),
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