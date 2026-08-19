import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../core/util/app_spacing.dart';
import 'avatar.dart';
import 'circle_icon_button.dart';
import 'expiring_banner.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.hasUnreadNotifications = false,
    this.expiringSoonCount = 0,
    this.onSearchTap,
    this.onNotificationTap,
    this.onAvatarTap,
    this.onExpiringBannerTap,
  });

  final String userName;
  final String? avatarUrl;
  final bool hasUnreadNotifications;
  final int expiringSoonCount;

  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onExpiringBannerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text('👋', style: TextStyle(fontSize: 18.sp)),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.w12,
              CircleIconButton(
                icon: Icons.search_rounded,
                onTap: onSearchTap,


              ),
              AppSpacing.w8,
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationTap,
                showBadge: hasUnreadNotifications,
              ),
              AppSpacing.w8,
              Avatar(name: userName, avatarUrl: avatarUrl, onTap: onAvatarTap),
            ],
          ),

          if (expiringSoonCount > 0) ...[
            SizedBox(height: 16.h),
            ExpiringBanner(
                count: expiringSoonCount,
                onTap: onExpiringBannerTap),
          ],
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good night,';
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

}



