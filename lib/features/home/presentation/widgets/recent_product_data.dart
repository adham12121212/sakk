import 'package:flutter/material.dart';

import '../../../../core/util/warranty_progress_color.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../../core/theme/app_icons.dart';

class RecentProductData {
  const RecentProductData({
    required this.title,
    required this.brand,
    required this.status,
    required this.daysRemaining,
    this.imageUrl,
    this.ringProgress,
  });

  factory RecentProductData.fromEntity(ProductEntity product) {
    return RecentProductData(
      title: product.name,
      brand: product.brand ?? '',
      status: product.status,
      daysRemaining: product.daysRemaining,
      imageUrl: product.imageUrl,
      ringProgress: product.status == WarrantyStatus.expired
          ? null
          : _remainingFraction(product),
    );
  }

  static double _remainingFraction(ProductEntity product) {
    final totalDays = product.warrantyEndDate
        .difference(product.purchaseDate)
        .inDays;
    if (totalDays <= 0) return 0;
    return (product.daysRemaining / totalDays).clamp(0.0, 1.0);
  }

  final String title;
  final String brand;
  final WarrantyStatus status;
  final int daysRemaining;
  final String? imageUrl;
  final double? ringProgress;
}

/// Product row card: warranty ring around the photo, name, "brand · days
/// left", status pill and a chevron. Used on Home, Products and Search.
class RecentProductTile extends StatelessWidget {
  const RecentProductTile({super.key, required this.data, this.onTap});

  final RecentProductData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColors = WarrantyStatusColors.of(context, data.status);
    final timeLeft = data.status == WarrantyStatus.expired
        ? l10n.warrantyExpired
        : l10n.daysLeft(data.daysRemaining);
    final subtitle = data.brand.trim().isEmpty
        ? timeLeft
        : '${data.brand} · $timeLeft';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _StatusRingThumbnail(
            data: data,
            // Same bands as the Details ring: by share of warranty left.
            ringColor: data.ringProgress == null
                ? statusColors.foreground
                : warrantyProgressColor(context, data.ringProgress!),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(status: data.status),
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

class _StatusRingThumbnail extends StatelessWidget {
  const _StatusRingThumbnail({required this.data, required this.ringColor});

  final RecentProductData data;
  final Color ringColor;

  static const double size = 52.0;
  static const double imageSize = 42.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: data.ringProgress ?? 1,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                data.ringProgress == null ? colorScheme.outline : ringColor,
              ),
            ),
          ),
          ClipOval(
            child: data.imageUrl != null
                ? Image.network(
                    data.imageUrl!,
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _fallbackIcon(context),
                  )
                : _fallbackIcon(context),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: imageSize,
      height: imageSize,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        AppIcons.productPlaceholder,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}
