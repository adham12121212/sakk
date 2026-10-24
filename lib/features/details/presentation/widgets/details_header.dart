import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/util/warranty_progress_color.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../scan/presentation/widgets/invoice_preview_dialog.dart';
import '../../../../core/theme/app_icons.dart';

/// The top of a product's page: back, share and download, the photo (tap
/// to zoom), then the name, brand, category, status and how much of the
/// warranty is left.
class DetailsHeader extends StatelessWidget {
  const DetailsHeader({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.warrantyProgress,
    required this.onBack,
    required this.onShare,
    required this.onDownload,
  });

  final ProductEntity product;
  final String? imageUrl;
  final double warrantyProgress;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = CategoryUi.color(product.category);
    final imageUrl = this.imageUrl;
    final subtitle = [
      if (product.brand != null && product.brand!.trim().isNotEmpty)
        product.brand!,
      CategoryUi.label(context, product.category),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(AppIcons.back),
                  onPressed: onBack,
                ),
                const Spacer(),
                _TextChip(label: l10n.share, onTap: onShare),
                if (imageUrl != null) ...[
                  const SizedBox(width: 8),
                  _TextChip(label: l10n.downloadInvoice, onTap: onDownload),
                ],
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4, 20.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null) ...[
                Semantics(
                  button: true,
                  label: l10n.invoicePreviewLabel,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: colorScheme.surfaceContainerHighest,
                      child: InkWell(
                        onTap: () =>
                            showInvoicePreviewDialog(context, imageUrl),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                CategoryUi.icon(product.category),
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CategoryUi.icon(product.category),
                        color: categoryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge,
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          StatusChip(status: product.status),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox.square(
                      dimension: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.square(
                            dimension: 56,
                            child: CircularProgressIndicator(
                              // Expired: a full red ring.
                              value: product.isExpired ? 1 : warrantyProgress,
                              strokeWidth: 5,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                warrantyStatusColor(context, product.status),
                              ),
                            ),
                          ),
                          Text(
                            '${formatLocalizedInt(Localizations.localeOf(context), (warrantyProgress * 100).round())}%',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A text-only pill in the top bar (Share, Download Invoice), with a 48
/// tall tap area.
class _TextChip extends StatelessWidget {
  const _TextChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colorScheme.surface,
                shape: StadiumBorder(
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
