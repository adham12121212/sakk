import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        child: isLoading
            ? SizedBox(
          width: 22.w,
          height: 22.w,
          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
        )
            : Text(label, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }
}