import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
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
    this.onPickAvatar,
    this.isUploadingAvatar = false,
  });

  final String displayName;
  final String displayEmail;
  final String? avatarUrl;
  final VoidCallback onBack;
  final VoidCallback? onPickAvatar;
  final bool isUploadingAvatar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final bottomRadius = BorderRadius.only(
      bottomLeft: Radius.circular(20.r),
      bottomRight: Radius.circular(20.r),
    );

    // Height follows the content rather than a fixed 350.h with children at
    // fixed .w offsets, so the email can't be clipped on short screens and
    // the back button sits below the status bar / notch (SafeArea).
    return ClipRRect(
      borderRadius: bottomRadius,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: bottomRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.85),
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
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 36.h),
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CircleIconButton(
                        icon: Icons.arrow_back,
                        semanticLabel: l10n.back,
                        onTap: onBack,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    ProfileAvatar(
                      name: displayName,
                      avatarUrl: avatarUrl,
                      size: 140,
                      onTap: onPickAvatar,
                      isUploading: isUploadingAvatar,
                      semanticLabel: l10n.changeProfilePhoto,
                    ),
                    SizedBox(height: 12.h),
                    Text(
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
                    SizedBox(height: 6.h),
                    Text(
                      displayEmail,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
