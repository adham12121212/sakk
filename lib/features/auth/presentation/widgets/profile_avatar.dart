
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 140,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.white, width: 2.r),
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: (size * 0.35).sp,
          ),
        ),
      ),
    );
  }
}