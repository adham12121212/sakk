import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../details/presentation/widgets/warranty_extras_section.dart' show claimStatusLabel;
import '../../../scan/presentation/widgets/datex.dart';
import '../../domain/enties/product_entity.dart';

/// Writes the products to a CSV file (opens in Excel, Numbers, Google Sheets)
/// and hands it to the share sheet. Headers, categories and statuses are in
/// the app's current language.
Future<void> shareProductsCsv(BuildContext context, List<ProductEntity> products) async {
  final l10n = AppLocalizations.of(context)!;
  final rows = <List<Object?>>[
    [
      l10n.productName,
      l10n.brand,
      l10n.category,
      l10n.price,
      l10n.store,
      l10n.purchaseDate,
      l10n.warrantyMonths,
      l10n.warrantyEnds,
      l10n.status,
      l10n.extraWarranties,
      l10n.returnBy,
      l10n.warrantyClaims,
      l10n.notes,
      l10n.invoiceTab,
    ],
    for (final p in products)
      [
        p.name,
        p.brand,
        CategoryUi.label(context, p.category),
        p.price == null ? null : '${p.price} ${p.currency}',
        p.store,
        p.purchaseDate.toIsoDate(),
        p.warrantyMonths,
        p.warrantyEndDate.toIsoDate(),
        switch (p.status) {
          WarrantyStatus.active => l10n.active,
          WarrantyStatus.expiring => l10n.expiring,
          WarrantyStatus.expired => l10n.expired,
        },
        p.extraWarranties
            .map((w) => '${w.provider}: ${w.startDate.toIsoDate()} – ${w.endDate.toIsoDate()}')
            .join('; '),
        p.returnByDate?.toIsoDate(),
        p.claims.map((c) => '${c.createdAt.toIsoDate()} ${claimStatusLabel(l10n, c.status)}: ${c.issue}').join('; '),
        p.notes,
        p.receiptUrl ?? p.imageUrl,
      ],
  ];

  final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sakk-products-${DateTime.now().toIsoDate()}.csv');
  // The byte-order mark makes Excel read the file as UTF-8, so Arabic shows
  // correctly instead of as garbled characters.
  await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

  await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')], subject: l10n.exportProducts);
}

/// Quotes a value when it contains a comma, quote or line break (RFC 4180).
/// A leading =, +, - or @ is prefixed with ' so a spreadsheet doesn't run
/// it as a formula; product names and notes come from receipts and users.
String _csvCell(Object? value) {
  if (value == null) return '';
  var text = value.toString();
  if (value is String && text.isNotEmpty && '=+-@'.contains(text[0])) text = "'$text";
  if (text.contains(RegExp(r'[",\r\n]'))) return '"${text.replaceAll('"', '""')}"';
  return text;
}
