import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';


class Avatar extends StatelessWidget {
  const Avatar({required this.name, this.avatarUrl, this.onTap});

  final String name;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          image: avatarUrl != null
              ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: avatarUrl == null
            ? Center(
          child: Text(
            initial,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        )
            : null,
      ),
    );
  }
}
