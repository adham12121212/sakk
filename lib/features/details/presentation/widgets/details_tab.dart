import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/entities/product_entity.dart';
import 'detail_row.dart';
import '../../../../core/theme/app_icons.dart';

class DetailsTab extends StatelessWidget {
  const DetailsTab({super.key, required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // Arabic gets Arabic-Indic digits, like the rest of the app.
    final appLocale = Localizations.localeOf(context);
    final locale = appLocale.languageCode == 'ar'
        ? 'ar_EG'
        : appLocale.toLanguageTag();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          DetailRow(
            icon: AppIcons.store,
            label: l10n.store,
            value: product.store ?? '—',
          ),
          DetailRow(
            icon: AppIcons.price,
            label: l10n.price,
            value: product.price != null
                ? '${product.currency} ${NumberFormat.decimalPattern(locale).format(product.price!.round())}'
                : '—',
          ),
          DetailRow(
            icon: AppIcons.calendar,
            label: l10n.purchaseDate,
            value: DateFormat.yMMMd(locale).format(product.purchaseDate),
          ),
          DetailRow(
            icon: AppIcons.shield,
            label: l10n.warrantyPeriod,
            value: '${product.warrantyMonths} ${l10n.months}',
          ),
          // An extra warranty can push coverage past the manufacturer's date.
          if (product.extraWarranties.isNotEmpty)
            DetailRow(
              icon: AppIcons.warranty,
              label: l10n.coveredUntil,
              value: DateFormat.yMMMd(locale).format(product.warrantyEndDate),
            ),
          if (product.returnByDate != null)
            DetailRow(
              icon: AppIcons.returnItem,
              label: l10n.returnBy,
              value: product.daysToReturn! < 0
                  ? l10n.returnWindowClosed(
                      DateFormat.yMMMd(locale).format(product.returnByDate!),
                    )
                  : l10n.returnByValue(
                      DateFormat.yMMMd(locale).format(product.returnByDate!),
                      product.daysToReturn!,
                    ),
            ),
          if (product.serialNumber != null)
            DetailRow(
              icon: AppIcons.receipt,
              label: l10n.serialNumber,
              value: product.serialNumber!,
            ),
          if (product.invoiceNumber != null)
            DetailRow(
              icon: AppIcons.receipt,
              label: l10n.invoiceNumber,
              value: product.invoiceNumber!,
            ),
          DetailRow(
            icon: AppIcons.category,
            label: l10n.category,
            value: CategoryUi.label(context, product.category),
            isLast: true,
          ),
          if (product.notes != null && product.notes!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Align(
                // Directional so Arabic notes start on the right.
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  product.notes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
