// widgets/warranty_banner.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/util/warranty_progress_color.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../../core/theme/app_icons.dart';

/// Warranty summary card: days left, expiry date, status shield and a slim
/// bar showing the share of the warranty that's left.
class WarrantyBanner extends StatelessWidget {
  const WarrantyBanner({super.key, required this.product, required this.warrantyProgress});

  final ProductEntity product;

  /// Share of the warranty left (0.0–1.0).
  final double warrantyProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = WarrantyStatusColors.of(context, product.status);
    final days = product.daysRemaining;
    final label = days > 0 ? l10n.daysLeft(days) : l10n.warrantyExpired;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final expiresLabel = l10n.expiresOnLabel(DateFormat.yMMMd(locale).format(product.warrantyEndDate));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: textTheme.titleLarge?.copyWith(color: status.foreground)),
                    const SizedBox(height: 2),
                    Text(expiresLabel, style: textTheme.bodySmall?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(14)),
                child: Icon(AppIcons.warranty, color: status.foreground, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: warrantyProgress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(warrantyProgressColor(context, warrantyProgress)),
            ),
          ),
        ],
      ),
    );
  }
}
