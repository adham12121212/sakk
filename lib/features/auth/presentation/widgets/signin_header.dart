import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/sakk_logo.dart';

class SigninHeader extends StatelessWidget {
  const SigninHeader({super.key});

  @override
  Widget build(BuildContext context) {


    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40.h),
        Container(
          width: 78.w,
          height: 78.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D7BFF), Color(0xFF5B3DF5)],
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