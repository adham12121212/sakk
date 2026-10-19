import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../installments/domain/entities/installment_plan.dart';
import '../../../installments/domain/installment_totals.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../subscriptions/domain/entities/billing_cycle.dart';
import '../../../subscriptions/domain/entities/user_subscription.dart';
import '../../../subscriptions/domain/renewal_schedule.dart';
import '../../../subscriptions/domain/subscription_totals.dart';
import '../../domain/monthly_summary.dart';

/// What goes in the report: the user's own products, their subscriptions
/// and installment plans, as of [today].
class PdfReportInput {
  const PdfReportInput({
    required this.products,
    required this.subscriptions,
    required this.plans,
    required this.today,
    this.accountEmail,
  });

  final List<ProductEntity> products;
  final List<UserSubscription> subscriptions;
  final List<InstallmentPlan> plans;
  final DateTime today;
  final String? accountEmail;
}

const _brand = PdfColor.fromInt(0xFF3171EF);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _rule = PdfColor.fromInt(0xFFE5E7EB);
const _headerFill = PdfColor.fromInt(0xFFF1F5FF);

/// Sakk Pro's PDF report, in the app's language (Arabic right to left):
/// a summary, then products, subscriptions and running installment plans
/// as tables. [regular] and [bold] must cover Arabic (the app bundles Cairo).
Future<Uint8List> buildPdfReport(
  PdfReportInput input, {
  required AppLocalizations l10n,
  required Locale locale,
  required pw.Font regular,
  required pw.Font bold,
}) {
  final rtl = locale.languageCode == 'ar';
  final dateTag = rtl ? 'ar_EG' : locale.toLanguageTag();
  String date(DateTime d) => DateFormat.yMMMd(dateTag).format(d);
  String count(int n) => formatLocalizedInt(locale, n);
  String money(double amount, String currency) =>
      '${formatLocalizedAmount(locale, amount)} ${currency == 'EGP' ? l10n.currencyEgp : currency}';
  String totals(Map<String, double> byCurrency) {
    if (byCurrency.isEmpty) return money(0, 'EGP');
    final ordered = [if (byCurrency.containsKey('EGP')) 'EGP', ...byCurrency.keys.where((c) => c != 'EGP')];
    return [for (final c in ordered) money(byCurrency[c]!, c)].join(' + ');
  }

  final today = DateTime(input.today.year, input.today.month, input.today.day);
  final running = input.plans.where((p) => p.isActive).toList();
  final summary = MonthlySummary.build(
    subscriptions: input.subscriptions,
    plans: input.plans,
    products: input.products,
    today: today,
  );

  final align = rtl ? pw.TextAlign.right : pw.TextAlign.left;
  final doc = pw.Document(title: l10n.pdfReportTitle, author: 'Sakk', creator: 'Sakk');

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 14, color: _brand), textAlign: align),
      );

  pw.Widget table(List<String> headers, List<List<String>> rows, List<double> flex) {
    if (rows.isEmpty) {
      return pw.Text(l10n.pdfReportNone, style: const pw.TextStyle(color: _muted), textAlign: align);
    }
    // The pdf package lays tables out left to right; reverse the columns so
    // Arabic reads from the right.
    List<T> ordered<T>(List<T> cells) => rtl ? cells.reversed.toList() : cells;
    pw.Widget cell(String text, {bool header = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(font: header ? bold : regular, fontSize: header ? 9 : 9.5),
          ),
        );
    final widths = ordered(flex);
    return pw.Table(
      columnWidths: {for (var i = 0; i < widths.length; i++) i: pw.FlexColumnWidth(widths[i])},
      border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _rule, width: 0.5)),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerFill),
          repeat: true,
          children: ordered([for (final h in headers) cell(h, header: true)]),
        ),
        for (final row in rows) pw.TableRow(children: ordered([for (final c in row) cell(c)])),
      ],
    );
  }

  pw.Widget summaryLine(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: ordered2(rtl, [
            pw.Expanded(child: pw.Text(label, textAlign: align, style: const pw.TextStyle(color: _muted))),
            pw.Text(value, style: pw.TextStyle(font: bold)),
          ]),
        ),
      );

  String statusOf(ProductEntity p) => switch (p.status) {
        WarrantyStatus.active => l10n.active,
        WarrantyStatus.expiring => l10n.expiring,
        WarrantyStatus.expired => l10n.expired,
      };

  doc.addPage(
    pw.MultiPage(
      maxPages: 200,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 36,
        marginRight: 36,
        marginTop: 36,
        marginBottom: 36,
      ),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Text(l10n.pdfReportTitle, textAlign: align, style: const pw.TextStyle(color: _muted, fontSize: 8)),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Text(
          l10n.pdfReportPage(count(context.pageNumber), count(context.pagesCount)),
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Text(l10n.pdfReportTitle, textAlign: align, style: pw.TextStyle(font: bold, fontSize: 22, color: _brand)),
        pw.SizedBox(height: 4),
        pw.Text(
          [l10n.pdfReportGenerated(date(input.today)), ?input.accountEmail].join('  ·  '),
          textAlign: align,
          style: const pw.TextStyle(color: _muted),
        ),

        heading(l10n.pdfReportSummary),
        summaryLine(l10n.totalProducts, count(input.products.length)),
        summaryLine(l10n.activeWarranties, count(input.products.where((p) => !p.isExpired).length)),
        summaryLine(l10n.expiringSoon, count(input.products.where((p) => p.isExpiring).length)),
        summaryLine(l10n.subscriptionsMonthlyTotal, totals(monthlyTotalsByCurrency(input.subscriptions))),
        summaryLine(l10n.pdfRemainingInstallments, totals(remainingByCurrency(input.plans))),
        summaryLine(l10n.monthlySummaryTotal, totals(summary.totals)),

        heading(l10n.products),
        table(
          [l10n.productName, l10n.store, l10n.purchaseDate, l10n.price, l10n.warrantyEnds, l10n.pdfColStatus],
          [
            for (final p in input.products)
              [
                p.brand == null || p.name.toLowerCase().contains(p.brand!.toLowerCase()) ? p.name : '${p.name} (${p.brand})',
                p.store ?? '',
                date(p.purchaseDate),
                p.price == null ? '' : money(p.price!, p.currency),
                date(p.warrantyEndDate),
                statusOf(p),
              ],
          ],
          [3, 2, 2, 1.6, 2, 1.4],
        ),

        heading(l10n.subscriptions),
        table(
          [l10n.productName, l10n.pdfColPlan, l10n.price, l10n.nextRenewal],
          [
            for (final s in input.subscriptions)
              [
                s.name,
                s.planName ?? '',
                s.billingCycle == BillingCycle.yearly
                    ? l10n.pricePerYear(money(s.price, s.currency))
                    : l10n.pricePerMonth(money(s.price, s.currency)),
                date(nextRenewalOnOrAfter(s.nextRenewalDate, s.billingCycle, today)),
              ],
          ],
          [3, 2, 2.4, 2],
        ),

        heading(l10n.installments),
        table(
          [l10n.productName, l10n.installmentProvider, l10n.pdfColPaid, l10n.pdfColRemaining, l10n.pdfColNextDue],
          [
            for (final p in running)
              [
                p.name,
                p.provider ?? '',
                '${count(p.paidCount)}/${count(p.totalCount)}',
                money(p.remainingBalance, p.currency),
                p.nextPayment == null
                    ? ''
                    : '${money(p.nextPayment!.amount, p.currency)} · ${date(p.nextPayment!.dueDate)}',
              ],
          ],
          [2.6, 1.8, 1, 1.8, 2.6],
        ),
      ],
    ),
  );
  return doc.save();
}

/// [children] in reading order for the page's direction.
List<pw.Widget> ordered2(bool rtl, List<pw.Widget> children) => rtl ? children.reversed.toList() : children;
