import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../core/util/app_spacing.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import 'avatar.dart';
import 'circle_icon_button.dart';
import 'expiring_banner.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.unreadNotificationCount = 0,
    this.expiringSoonCount = 0,
    this.onSearchTap,
    this.onNotificationTap,
    this.onAvatarTap,
    this.onExpiringBannerTap,
  });

  final String userName;
  final String? avatarUrl;
  final int unreadNotificationCount;
  final int expiringSoonCount;

  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onExpiringBannerTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final notificationsLabel = unreadNotificationCount > 0
        ? '${l10n.notifications}, ${l10n.unreadNotificationsLabel(unreadNotificationCount, formatLocalizedInt(Localizations.localeOf(context), unreadNotificationCount))}'
        : l10n.notifications;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSizes.s20,
        AppSizes.s16,
        AppSizes.s20,
        AppSizes.s16,
      ),
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
                      _greeting(context),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
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
                              color: Theme.of(context).colorScheme.onSurface,
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
                semanticLabel: l10n.search,
                onTap: onSearchTap,
                color: colorScheme.onSurface,
              ),
              AppSpacing.w8,
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                semanticLabel: notificationsLabel,
                onTap: onNotificationTap,
                badgeCount: unreadNotificationCount,
                color: colorScheme.onSurface,
              ),
              AppSpacing.w8,
              Avatar(
                name: userName,
                avatarUrl: avatarUrl,
                onTap: onAvatarTap,
                semanticLabel: l10n.openProfile,
              ),
            ],
          ),
          if (expiringSoonCount > 0) ...[
            SizedBox(height: 16.h),
            ExpiringBanner(
              count: expiringSoonCount,
              onTap: onExpiringBannerTap,
            ),
          ],
        ],
      ),
    );
  }

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.goodNight;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }
}
