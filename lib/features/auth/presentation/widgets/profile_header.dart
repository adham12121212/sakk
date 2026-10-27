import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pro/presentation/widgets/plan_badge.dart';
import 'profile_avatar.dart';

/// The user's card at the top of Profile: photo (tap to change it), name,
/// plan and email.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.displayEmail,
    required this.avatarUrl,
    this.onPickAvatar,
    this.isUploadingAvatar = false,
  });

  final String displayName;
  final String displayEmail;
  final String? avatarUrl;
  final VoidCallback? onPickAvatar;
  final bool isUploadingAvatar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          ProfileAvatar(
            name: displayName,
            avatarUrl: avatarUrl,
            size: 76,
            onTap: onPickAvatar,
            isUploading: isUploadingAvatar,
            semanticLabel: l10n.changeProfilePhoto,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                PlanBadge.live(size: PlanBadgeSize.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
