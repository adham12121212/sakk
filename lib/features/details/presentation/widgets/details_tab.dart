import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/enties/product_entity.dart';
import 'detail_row.dart';

class DetailsTab extends StatelessWidget {
  const DetailsTab({super.key, required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          DetailRow(icon: Icons.location_on_outlined, label: l10n.store, value: product.store ?? '—'),
          DetailRow(
            icon: Icons.credit_card_outlined,
            label: l10n.price,
            value: product.price != null ? '${product.currency} ${product.price!.toStringAsFixed(0)}' : '—',
          ),
          DetailRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.purchaseDate,
            value: '${product.purchaseDate.year}-${product.purchaseDate.month.toString().padLeft(2, '0')}-${product.purchaseDate.day.toString().padLeft(2, '0')}',
          ),
          DetailRow(
            icon: Icons.shield_outlined,
            label: l10n.warrantyPeriod,
            value: '${product.warrantyMonths} ${l10n.months}',
          ),
          DetailRow(
            icon: Icons.layers_outlined,
            label: l10n.category,
            value: CategoryUi.label(context, product.category),
            isLast: true,
          ),
          if (product.notes != null && product.notes!.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(product.notes!, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
              ),
            ),
        ],
      ),
    );
  }
}