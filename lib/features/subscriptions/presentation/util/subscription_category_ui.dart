import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/subscription_category.dart';

/// Icon, colour and label for each subscription category.
class SubscriptionCategoryUi {
  SubscriptionCategoryUi._();

  static IconData icon(SubscriptionCategory category) => switch (category) {
    SubscriptionCategory.streaming => AppIcons.streaming,
    SubscriptionCategory.music => AppIcons.music,
    SubscriptionCategory.gaming => AppIcons.gaming,
    SubscriptionCategory.cloud => AppIcons.cloud,
    SubscriptionCategory.productivity => AppIcons.productivity,
    SubscriptionCategory.ai => AppIcons.ai,
    SubscriptionCategory.delivery => AppIcons.delivery,
    SubscriptionCategory.telecom => AppIcons.telecom,
    SubscriptionCategory.other => AppIcons.otherCategory,
  };

  static Color color(SubscriptionCategory category) => switch (category) {
    SubscriptionCategory.streaming => const Color(0xFFEF4444),
    SubscriptionCategory.music => const Color(0xFF22C55E),
    SubscriptionCategory.gaming => const Color(0xFF8B5CF6),
    SubscriptionCategory.cloud => const Color(0xFF3B82F6),
    SubscriptionCategory.productivity => const Color(0xFF0EA5E9),
    SubscriptionCategory.ai => const Color(0xFF6366F1),
    SubscriptionCategory.delivery => const Color(0xFFF97316),
    SubscriptionCategory.telecom => const Color(0xFFF59E0B),
    SubscriptionCategory.other => const Color(0xFF9CA3AF),
  };

  static String label(BuildContext context, SubscriptionCategory category) {
    final l10n = AppLocalizations.of(context)!;
    return switch (category) {
      SubscriptionCategory.streaming => l10n.subscriptionCategoryStreaming,
      SubscriptionCategory.music => l10n.subscriptionCategoryMusic,
      SubscriptionCategory.gaming => l10n.subscriptionCategoryGaming,
      SubscriptionCategory.cloud => l10n.subscriptionCategoryCloud,
      SubscriptionCategory.productivity =>
        l10n.subscriptionCategoryProductivity,
      SubscriptionCategory.ai => l10n.subscriptionCategoryAi,
      SubscriptionCategory.delivery => l10n.subscriptionCategoryDelivery,
      SubscriptionCategory.telecom => l10n.subscriptionCategoryTelecom,
      SubscriptionCategory.other => l10n.subscriptionCategoryOther,
    };
  }
}
