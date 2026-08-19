import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class CapsuleShell extends StatelessWidget {
  const CapsuleShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: child,
    );
  }
}

/// A capsule-shaped text form field, styled to match [CapsuleShell].
class CapsuleField extends StatelessWidget {
  const CapsuleField({
    super.key,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.withOpacity(0.08),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}