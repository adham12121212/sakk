import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/enties/product_entity.dart';

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
    final totalDays =
        product.warrantyEndDate.difference(product.purchaseDate).inDays;
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

class RecentProductTile extends StatelessWidget {
  const RecentProductTile({super.key, required this.data, this.onTap});

  final RecentProductData data;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (data.status) {
      case WarrantyStatus.active:
        return AppColors.success;
      case WarrantyStatus.expiring:
        return const Color(0xFFF59E0B);
      case WarrantyStatus.expired:
        return AppColors.error;
    }
  }

  Color get _statusBgColor {
    switch (data.status) {
      case WarrantyStatus.active:
        return AppColors.success.withOpacity(0.12);
      case WarrantyStatus.expiring:
        return const Color(0xFFFEF3C7);
      case WarrantyStatus.expired:
        return AppColors.error.withOpacity(0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final statusLabel = switch (data.status) {
      WarrantyStatus.active => l10n.active,
      WarrantyStatus.expiring => l10n.expiring,
      WarrantyStatus.expired => l10n.expired,
    };
    final subtitle = data.status == WarrantyStatus.expired
        ? l10n.warrantyExpired
        : l10n.daysLeft(data.daysRemaining);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: EdgeInsets.all(AppSizes.s12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            _StatusRingThumbnail(data: data, ringColor: _statusColor),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600,color:  colorScheme.onSurface),
                  ),
                  SizedBox(height: 2.h),
                  Text(data.brand, style: TextStyle(fontSize: 13.sp, color: colorScheme.onSurface.withOpacity(0.6))),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14.sp, color: colorScheme.onSurface.withOpacity(0.5)),
                      SizedBox(width: 4.w),
                      Text(subtitle, style: TextStyle(fontSize: 12.sp, color: colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.s10, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: _statusColor),
                  ),
                ),
                SizedBox(height: 10.h),
                Icon(Icons.chevron_left_rounded, size: 20.sp, color: colorScheme.onSurface.withOpacity(0.4), textDirection: TextDirection.rtl),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRingThumbnail extends StatelessWidget {
  const _StatusRingThumbnail({required this.data, required this.ringColor});

  final RecentProductData data;
  final Color ringColor;

  static const double size = 52.0;
  static const double imageSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (data.ringProgress != null)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: data.ringProgress,
                strokeWidth: 3,
                backgroundColor: colorScheme.outline,
                valueColor: AlwaysStoppedAnimation(ringColor),
              ),
            )
          else
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 3),
              ),
            ),
          ClipOval(
            child: data.imageUrl != null
                ? Image.network(
              data.imageUrl!,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('[RecentProductTile] Image.network failed for ${data.imageUrl}: $error');
                return _fallbackIcon(
                  context
                );
              },
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
      child: Icon(Icons.devices_other_rounded, color: colorScheme.onSurface.withOpacity(0.4), size: 20.sp),
    );
  }

}