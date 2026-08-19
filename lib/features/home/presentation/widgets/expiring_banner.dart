import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';



class ExpiringBanner extends StatelessWidget {
  const ExpiringBanner({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  static const _amber = Color(0xFFF59E0B);
  static const _amberBg = Color(0xFFFEF3C7);

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? '1 warranty is expiring soon'
        : '$count warranties are expiring soon';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxxl),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s12),
        decoration: BoxDecoration(
          color: _amberBg,
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          border: Border.all(color: _amber.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _amber, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}