import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../products/domain/enties/product_entity.dart';

class RecentProductData {
  const RecentProductData({
    required this.title,
    required this.brand,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBgColor,
    required this.subtitle,
    this.imageUrl,
    this.ringProgress,
    this.ringColor,
  });


  factory RecentProductData.fromEntity(ProductEntity product) {
    late final String statusLabel;
    late final Color statusColor;
    late final Color statusBgColor;
    double? ringProgress;

    switch (product.status) {
      case WarrantyStatus.active:
        statusLabel = 'Active';
        statusColor = AppColors.success;
        statusBgColor = AppColors.success.withOpacity(0.12);
        ringProgress = _remainingFraction(product);
        break;
      case WarrantyStatus.expiring:
        statusLabel = 'Expiring';
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFFEF3C7);
        ringProgress = _remainingFraction(product);
        break;
      case WarrantyStatus.expired:
        statusLabel = 'Expired';
        statusColor = AppColors.error;
        statusBgColor = AppColors.error.withOpacity(0.12);
        ringProgress = null;
        break;
    }

    return RecentProductData(
      title: product.name,
      brand: product.brand ?? '',
      subtitle: product.status == WarrantyStatus.expired
          ? 'Warranty expired'
          : '${product.daysRemaining} days left',
      statusLabel: statusLabel,
      statusColor: statusColor,
      statusBgColor: statusBgColor,
      imageUrl: product.imageUrl,
      ringProgress: ringProgress,
      ringColor: statusColor,
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

  final String statusLabel;
  final Color statusColor;
  final Color statusBgColor;

  final String subtitle;

  final String? imageUrl;

  final double? ringProgress;
  final Color? ringColor;
}

class RecentProductTile extends StatelessWidget {
  const RecentProductTile({super.key, required this.data, this.onTap});

  final RecentProductData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: EdgeInsets.all(AppSizes.s12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _StatusRingThumbnail(data: data),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    data.brand,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14.sp, color: Colors.grey.shade500),
                      SizedBox(width: 4.w),
                      Text(
                        data.subtitle,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                      ),
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
                    color: data.statusBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    data.statusLabel,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: data.statusColor,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                Icon(
                  Icons.chevron_left_rounded,
                  size: 20.sp,
                  color: Colors.grey.shade400,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRingThumbnail extends StatelessWidget {
  const _StatusRingThumbnail({required this.data});

  final RecentProductData data;

  static const double size = 52.0;
  static const double imageSize = 44.0;

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(data.ringColor ?? Colors.grey),
              ),
            )
          else
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 3),
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
                return _fallbackIcon();
              },
            )
                : _fallbackIcon(),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      width: imageSize,
      height: imageSize,
      color: Colors.grey.shade100,
      child: Icon(Icons.devices_other_rounded, color: Colors.grey.shade400, size: 20.sp),
    );
  }
}