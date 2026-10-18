import '../../features/products/data/product_data_source/product_data_source.dart';
import '../../features/household/data/household_data_source.dart';
import '../../features/installments/domain/usecase/update_installment_plan_usecase.dart';
import '../../features/subscriptions/data/subscription_data_source/subscription_data_source.dart';
import '../../l10n/app_localizations.dart';
import 'failure.dart';

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
  if (message == SubscriptionDataSourceImpl.unreadableSubscription) return l10n.subscriptionScanUnreadable;
  if (message == HouseholdDataSource.invalidInviteCode) return l10n.invalidInviteCode;
  if (message == HouseholdDataSource.alreadyInHousehold) return l10n.alreadyInHousehold;
  if (message == HouseholdDataSource.householdFull) return l10n.householdFull;
  if (message == UpdateInstallmentPlanUseCase.tooFewInstallments) return l10n.installmentsCountBelowPaidGeneric;
  return l10n.errorGeneric;
}
