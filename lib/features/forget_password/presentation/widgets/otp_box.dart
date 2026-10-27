import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpBox extends StatelessWidget {
  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44.w,
      height: 48.h,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: Theme.of(context).textTheme.titleLarge,
        // Fill and borders come from the app theme (same as other fields).
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
