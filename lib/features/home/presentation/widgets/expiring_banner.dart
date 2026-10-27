import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/theme/app_icons.dart';

/// Soft amber card: "N warranties expiring soon" with a chevron.
class ExpiringBanner extends StatelessWidget {
  const ExpiringBanner({super.key, required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.warrantiesExpiringSoon(
      count,
      formatLocalizedInt(Localizations.localeOf(context), count),
    );
    final palette = context.palette;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      color: palette.warningContainer,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.expiring, color: palette.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          if (onTap != null)
            Icon(AppIcons.chevronForward, color: palette.warning),
        ],
      ),
    );
  }
}
