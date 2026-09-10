
// widgets/warranty_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/enties/product_entity.dart';

class WarrantyBanner extends StatelessWidget {
  const WarrantyBanner({super.key, required this.product, required this.statusColor});

  final ProductEntity product;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = product.daysRemaining;
    final label = days > 0 ? l10n.daysLeft(days) : l10n.warrantyExpired;
    final expiresLabel = l10n.expiresOnLabel(
      '${product.warrantyEndDate.year}-${product.warrantyEndDate.month.toString().padLeft(2, '0')}-${product.warrantyEndDate.day.toString().padLeft(2, '0')}',
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: statusColor)),
                SizedBox(height: 2.h),
                Text(expiresLabel, style: TextStyle(fontSize: 13.sp, color: statusColor.withOpacity(0.85))),
              ],
            ),
          ),
          Icon(Icons.shield_outlined, color: statusColor, size: 26.sp),
        ],
      ),
    );
  }
}