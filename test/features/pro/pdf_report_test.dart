import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sakk/features/pro/presentation/util/pdf_report.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/l10n/app_localizations.dart';

import '../installments/installment_fixtures.dart';

/// Set PDF_REPORT_OUT to a folder to keep the PDFs and look at them.
final _out = Platform.environment['PDF_REPORT_OUT'];

void main() {
  // The app gets these from flutter_localizations.
  setUpAll(() => initializeDateFormatting());

  final regular = pw.Font.ttf(File('assets/fonts/Cairo-Regular.ttf').readAsBytesSync().buffer.asByteData());
  final bold = pw.Font.ttf(File('assets/fonts/Cairo-Bold.ttf').readAsBytesSync().buffer.asByteData());
  final today = DateTime(2026, 10, 19);

  final input = PdfReportInput(
    today: today,
    accountEmail: 'user@example.com',
    products: [
      ProductEntity(
        id: '1',
        name: 'تلاجة شارب ١٨ قدم',
        brand: 'Sharp',
        store: 'B.TECH',
        price: 28500,
        purchaseDate: DateTime(2025, 11, 2),
        warrantyMonths: 24,
      ),
      ProductEntity(
        id: '2',
        name: 'iPhone 16 Pro',
        store: 'Apple Store',
        price: 72000,
        purchaseDate: DateTime(2025, 12, 20),
        warrantyMonths: 12,
      ),
      ProductEntity(id: '3', name: 'غسالة توشيبا', purchaseDate: DateTime(2024, 1, 5), warrantyMonths: 24),
    ],
    subscriptions: [
      UserSubscription(
        id: 'n',
        customName: 'Netflix',
        planName: 'Premium',
        price: 240,
        billingCycle: BillingCycle.monthly,
        nextRenewalDate: DateTime(2026, 10, 25),
      ),
      UserSubscription(
        id: 's',
        customName: 'شاهد',
        planName: 'VIP',
        price: 1000,
        billingCycle: BillingCycle.yearly,
        nextRenewalDate: DateTime(2027, 2, 1),
      ),
    ],
    plans: [plan('موبايل', t: terms(total: 12000, count: 12, start: DateTime(2026, 9, 5)), paid: {0})],
  );

  for (final lang in ['ar', 'en']) {
    test('$lang: builds a PDF with every section', () async {
      final locale = Locale(lang);
      final l10n = await AppLocalizations.delegate.load(locale);
      final bytes = await buildPdfReport(input, l10n: l10n, locale: locale, regular: regular, bold: bold);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(5000));
      if (_out != null) File('$_out/report_$lang.pdf').writeAsBytesSync(bytes);
    });
  }

  test('empty account: still a valid report', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    final bytes = await buildPdfReport(
      PdfReportInput(products: const [], subscriptions: const [], plans: const [], today: today),
      l10n: l10n,
      locale: const Locale('ar'),
      regular: regular,
      bold: bold,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('a long list runs over several pages instead of failing', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final many = [
      for (var i = 0; i < 300; i++)
        ProductEntity(id: '$i', name: 'Product $i', purchaseDate: DateTime(2026, 1, 1), warrantyMonths: 12),
    ];
    final bytes = await buildPdfReport(
      PdfReportInput(products: many, subscriptions: const [], plans: const [], today: today),
      l10n: l10n,
      locale: const Locale('en'),
      regular: regular,
      bold: bold,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
