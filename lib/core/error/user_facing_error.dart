import '../../features/products/data/product_data_source/product_data_source.dart';
import '../../l10n/app_localizations.dart';
import 'Failure.dart';

/// Turns a failure message from a cubit into something safe to show users.
///
/// Repository messages are English and sometimes technical (exception text,
/// status codes), and they're already logged where they happen, so the UI
/// distinguishes "no connection" and the receipt scanner's own codes from
/// everything else.
String userFacingError(AppLocalizations l10n, String? message) {
  if (message == NetworkFailure.noConnectionMessage) return l10n.errorNoInternet;
  if (message == ProductDataSourceImpl.unreadableReceipt) return l10n.scanUnreadable;
  if (message == ProductDataSourceImpl.aiBusy) return l10n.scanBusy;
  if (message == ProductDataSourceImpl.pdfUnreadable) return l10n.pdfUnreadable;
  return l10n.errorGeneric;
}
