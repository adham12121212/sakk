import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';


class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    this.onTap,
    this.showBadge = false,
    this.color = AppColors.black,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
                icon,
                size: 20.sp,
                color:  color ),
          ),
          if (showBadge)
            Positioned(
              top: 8,
              right: 10,
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
