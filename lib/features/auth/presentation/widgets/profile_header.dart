import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../home/presentation/widgets/circle_icon_button.dart';
import '../../../spalsh/presentation/widgets/blob.dart';
import 'profile_avatar.dart';


class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.displayEmail,
    required this.avatarUrl,
    required this.onBack,
  });

  final String displayName;
  final String displayEmail;
  final String? avatarUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 350.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.primary,
          ],
        ),
      ),
      child: Stack(
        children: [

          Positioned(
            top: -60.w,
            left: -40.w,
            child: IgnorePointer(child: Blob(size: 220.w)),
          ),
          Positioned(
            bottom: -80.w,
            right: -60.w,
            child: IgnorePointer(child: Blob(size: 260.w)),
          ),

          Positioned(
            top: 60.w,
            left: 20.w,
            child: CircleIconButton(
              icon: Icons.arrow_back,
              onTap: onBack,
              color: AppColors.white,
            ),
          ),

          Positioned(
            top: 100.w,
            right: 100.w,
            left: 100.w,
            child: ProfileAvatar(
              name: displayName,
              avatarUrl: avatarUrl,
              size: 140,
            ),
          ),

          Positioned(
            top: 250.w,
            right: 24.w,
            left: 24.w,
            child: Center(
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Positioned(
            top: 282.w,
            right: 24.w,
            left: 24.w,
            child: Center(
              child: Text(
                displayEmail,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.85),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}