import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/get_it.dart';
import '../../../core/route/app_router.dart';
import '../data/purchases_gateway.dart';
import '../domain/pro_limit.dart';
import 'cubit/pro_cubit.dart';

/// Opening the paywall and the store's subscription page, and the checks
/// the add and AI buttons make before going ahead.
///
/// The checks only save the user a trip to a form that would be refused:
/// the server enforces every limit anyway.
abstract final class ProActions {
  static ProCubit get cubit => getIt<ProCubit>();

  /// Null where it isn't set up (widget tests of other screens); the checks
  /// then let everything through and the Pro widgets show nothing.
  static ProCubit? get maybeCubit =>
      getIt.isRegistered<ProCubit>() ? getIt<ProCubit>() : null;

  static Future<void> openPaywall(
    BuildContext context, [
    PaywallReason reason = PaywallReason.upgrade,
  ]) => context.push(AppRoutes.paywall, extra: reason);

  /// Google Play's page for this subscription (cancel, change plan, fix
  /// the payment method).
  static Future<void> manageSubscription() async {
    final productId = cubit.state.status.entitlement?.productId;
    final uri = await getIt<PurchasesGateway>().managementUri(
      productId: productId,
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// True if the user can add another [item]; otherwise opens the paywall.
  static bool ensureCanAdd(BuildContext context, LimitedItem item) {
    final pro = maybeCubit;
    if (pro == null || pro.canAdd(item)) return true;
    openPaywall(context, ProLimit.reasonForItem(item));
    return false;
  }

  /// True if today's [type] quota has some left; otherwise opens the paywall.
  static bool ensureCanUse(BuildContext context, QuotaType type) {
    final pro = maybeCubit;
    // A Pro user at the fair-use cap gets the server's "try tomorrow".
    if (pro == null || pro.canUse(type) || pro.isPro) return true;
    openPaywall(
      context,
      type == QuotaType.scan
          ? PaywallReason.scanLimit
          : PaywallReason.chatLimit,
    );
    return false;
  }

  /// True for Pro users; otherwise opens the paywall for [reason].
  static bool ensurePro(BuildContext context, PaywallReason reason) {
    if (maybeCubit?.isPro ?? true) return true;
    openPaywall(context, reason);
    return false;
  }
}
