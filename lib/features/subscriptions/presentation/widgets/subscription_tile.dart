import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_subscription.dart';
import '../util/subscription_format.dart';
import 'subscription_logo.dart';

/// List row: logo, name, "plan · renews in N days" and the price per cycle.
class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({
    super.key,
    required this.subscription,
    required this.today,
    this.onTap,
  });

  final UserSubscription subscription;
  final DateTime today;
  final VoidCallback? onTap;

  /// Renewals this close are highlighted.
  static const _soonDays = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final daysLeft = subscription.daysLeft(today);
    final isSoon = daysLeft >= 0 && daysLeft <= _soonDays;
    final when = renewalLabel(l10n, daysLeft);
    final plan = subscription.planName;
    final hasPlan =
        plan != null && plan.isNotEmpty && plan != subscription.name;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SubscriptionLogo(
            name: subscription.name,
            logoUrl: subscription.logoUrl,
            domain: subscription.domain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      if (hasPlan) TextSpan(text: '$plan · '),
                      TextSpan(
                        text: when,
                        style: isSoon
                            ? TextStyle(
                                color: context.palette.warning,
                                fontWeight: FontWeight.w600,
                              )
                            : null,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatPricePerCycle(
              context,
              subscription.price,
              subscription.currency,
              subscription.billingCycle,
            ),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 2),
          Icon(
            AppIcons.chevronForward,
            size: 20,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
