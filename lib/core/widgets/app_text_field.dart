import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  final String? Function(String?)? validator;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final IconData? prefixIcon;
  final Widget? suffixIcon;

  final bool obscureText;
  final bool enabled;
  final bool readOnly;

  final int maxLines;

  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
          ),
        ),

        SizedBox(height: 8.h),

        TextFormField(
          cursorHeight: 15.h,
          cursorColor: AppColors.primary,
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,

            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            prefixIconColor: AppColors.primary,
            suffixIcon: suffixIcon,
            suffixIconColor: AppColors.primary,

            filled: true,

            fillColor: AppColors.grey.withOpacity(.1),

            contentPadding: EdgeInsets.symmetric(
              horizontal: 18.w,
              vertical: 16.h,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.error,
              ),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}