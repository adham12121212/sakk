import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/sakk_logo.dart';
import '../../../../core/constant/app_colors.dart';
import 'language_switch.dart';

class SigninHeader extends StatelessWidget {
  const SigninHeader({super.key});

  @override
  Widget build(BuildContext context) {


    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LanguageSwitch(),
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          width: 78.w,
          height: 78.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.brandGradientColors,
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: const [
              BoxShadow(color: Color(0x404A5CFA), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: SakkLogo(size: 78.w),
        ),

      ],
    );
  }
}