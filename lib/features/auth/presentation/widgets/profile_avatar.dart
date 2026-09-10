import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 140,
    this.onTap,
    this.isUploading = false,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final VoidCallback? onTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size.w,
            height: size.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              border: Border.all(color: AppColors.white, width: 2.r),
              image: hasPhoto
                  ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint('[ProfileAvatar] Failed to load $avatarUrl: $exception');
                  },
              )
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
          ),
          if (isUploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.35),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28.w,
                    height: 28.w,
                    child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (onTap != null && !isUploading)
            PositionedDirectional(
              bottom: 0,
              end: 0,
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: AppColors.white, width: 2.r),
                ),
                child: Icon(Icons.camera_alt_rounded, size: 18.sp, color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}