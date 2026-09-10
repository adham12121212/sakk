import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/enties/scanned_receipt.dart';
import 'datex.dart';


class ProcessingFieldSpec {
  const ProcessingFieldSpec({
    required this.label,
    required this.valueOf,
    required this.skeletonWidth,
  });

  final String label;
  final String? Function(ScannedReceiptData data) valueOf;
  final double skeletonWidth;
}


List<ProcessingFieldSpec> buildScanProcessingFields(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).languageCode;

  return [
    ProcessingFieldSpec(
      label: l10n.productName,
      valueOf: (d) => d.productName,
      skeletonWidth: 150,
    ),
    ProcessingFieldSpec(
      label: l10n.brand,
      valueOf: (d) => d.brand,
      skeletonWidth: 90,
    ),
    ProcessingFieldSpec(
      label: l10n.price,
      valueOf: (d) => d.price == null ? null : l10n.priceSar(d.price!.toStringAsFixed(0)),
      skeletonWidth: 110,
    ),
    ProcessingFieldSpec(
      label: l10n.purchaseDate,
      valueOf: (d) => d.purchaseDate?.toShortLabel(locale),
      skeletonWidth: 130,
    ),
    ProcessingFieldSpec(
      label: l10n.warrantyDuration,
      valueOf: (d) => d.warrantyMonths == null ? null : l10n.warrantyMonthsValue(d.warrantyMonths!),
      skeletonWidth: 100,
    ),
    ProcessingFieldSpec(
      label: l10n.store,
      valueOf: (d) => d.store,
      skeletonWidth: 120,
    ),
  ];
}