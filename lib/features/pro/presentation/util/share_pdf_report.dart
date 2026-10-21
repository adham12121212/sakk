import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../../../installments/presentation/cubit/installments_cubit.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../domain/pro_limit.dart';
import '../pro_actions.dart';
import 'pdf_report.dart';

/// Sakk Pro's PDF report: builds `sakk-report-<date>.pdf` from the app-wide
/// lists and opens the share sheet. Free users get the paywall.
Future<void> sharePdfReport(BuildContext context) async {
  if (!ProActions.ensurePro(context, PaywallReason.pdfReport)) return;
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context);
  try {
    final products = getIt<ProductsCubit>();
    final subscriptions = getIt<SubscriptionsCubit>();
    final installments = getIt<InstallmentsCubit>();
    // Lists nobody has opened yet are read now; a report missing a section
    // would look like the user has nothing there.
    await Future.wait([
      if (!products.state.hasLoadedOnce) products.refresh(),
      if (!subscriptions.state.hasLoadedOnce) subscriptions.refresh(),
      if (!installments.state.hasLoadedOnce) installments.refresh(),
    ]);
    if (!products.state.hasLoadedOnce || !subscriptions.state.hasLoadedOnce || !installments.state.hasLoadedOnce) {
      throw StateError('A list could not be loaded');
    }

    // The user's own products only: household members' are theirs to report.
    final me = getIt<GetUserUseCase>()();
    final fonts = await Future.wait([
      rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
      rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    ]);
    final bytes = await buildPdfReport(
      PdfReportInput(
        products: products.state.products.where((p) => p.isOwnedBy(me?.id)).toList(),
        subscriptions: subscriptions.state.subscriptions,
        plans: installments.state.plans,
        today: DateTime.now(),
        accountEmail: me?.email,
      ),
      l10n: l10n,
      locale: locale,
      regular: pw.Font.ttf(fonts[0]),
      bold: pw.Font.ttf(fonts[1]),
    );

    final dir = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/sakk-report-$date.pdf');
    await file.writeAsBytes(bytes);
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], subject: l10n.pdfReportTitle),
    );
  } catch (e, st) {
    getIt<AppLogger>().error('PDF report failed', error: e, stackTrace: st);
    if (context.mounted) AppSnackBar.error(context, l10n.pdfReportFailed);
  }
}
