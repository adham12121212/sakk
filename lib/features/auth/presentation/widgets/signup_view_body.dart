import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/auth/presentation/widgets/signup_form.dart';
import 'package:sakk/features/auth/presentation/widgets/signup_header.dart';

class SignupViewBody extends StatelessWidget {
  const SignupViewBody({super.key, required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            const SignupHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SignupForm(isLoading: isLoading),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}