import '../../features/auth/data/auth_data_source/auth_data_source.dart';
import '../../features/chat/data/chat_data_source/chat_data_source.dart';
import '../../features/products/data/product_data_source/product_data_source.dart';
import '../../features/pro/domain/pro_limit.dart';
import '../../features/household/data/household_data_source.dart';
import '../../features/installments/data/installment_data_source/installment_data_source.dart';
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
  if (message == NetworkFailure.noConnectionMessage) {
    return l10n.errorNoInternet;
  }
  if (message == ProductDataSourceImpl.unreadableReceipt) {
    return l10n.scanUnreadable;
  }
  if (message == ProductDataSourceImpl.aiBusy) return l10n.scanBusy;
  if (message == ProductDataSourceImpl.pdfUnreadable) return l10n.pdfUnreadable;
  if (message == ProductDataSourceImpl.voiceUnheard) return l10n.voiceUnheard;
  if (message == SubscriptionDataSourceImpl.unreadableSubscription) {
    return l10n.subscriptionScanUnreadable;
  }
  if (message == HouseholdDataSource.invalidInviteCode) {
    return l10n.invalidInviteCode;
  }
  if (message == HouseholdDataSource.alreadyInHousehold) {
    return l10n.alreadyInHousehold;
  }
  if (message == HouseholdDataSource.householdFull) return l10n.householdFull;
  if (message == InstallmentDataSourceImpl.unreadableInstallment) {
    return l10n.installmentScanUnreadable;
  }
  if (message == UpdateInstallmentPlanUseCase.tooFewInstallments) {
    return l10n.installmentsCountBelowPaidGeneric;
  }
  if (message == ChatDataSourceImpl.aiBusy) return l10n.chatBusy;
  if (message == AuthDataSourceImpl.resetRateLimited) {
    return l10n.resetRateLimited;
  }
  if (message == AuthDataSourceImpl.resetInvalidEmail) return l10n.invalidEmail;
  if (message == AuthDataSourceImpl.resetInvalidCode) {
    return l10n.resetInvalidCode;
  }
  if (message == AuthDataSourceImpl.resetSamePassword) {
    return l10n.resetSamePassword;
  }
  final limit = ProLimit.kindOf(message);
  if (limit != null) return _limitMessage(l10n, limit);
  return l10n.errorGeneric;
}

/// The free plan's limit for [kind] was reached (the paywall opens too).
String _limitMessage(AppLocalizations l10n, String kind) {
  return switch (kind) {
    'products' => l10n.limitReachedProducts,
    'subscriptions' => l10n.limitReachedSubscriptions,
    'installments' => l10n.limitReachedInstallments,
    'papers' => l10n.limitReachedPapers,
    'scan' => l10n.limitReachedScan,
    'chat' => l10n.limitReachedChat,
    'voice' => l10n.limitReachedVoice,
    _ => l10n.limitReachedFairUse,
  };
}
