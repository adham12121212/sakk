import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/brand_gradient_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/purchases_gateway.dart';
import '../../domain/entities/pro_status.dart';
import '../../domain/pro_limit.dart';
import '../cubit/paywall_cubit.dart';
import '../cubit/pro_cubit.dart';
import '../pro_actions.dart';

/// Sakk Pro's paywall: free vs Pro, the two plans with their store prices
/// (yearly highlighted with its real saving), the free trial, and what
/// Google Play requires: the auto-renew terms, restore, terms and privacy.
class PaywallView extends StatefulWidget {
  const PaywallView({super.key, this.reason = PaywallReason.upgrade});

  final PaywallReason reason;

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  @override
  void initState() {
    super.initState();
    context.read<PaywallCubit>().load();
    // Today's counters and the limits shown in the table.
    ProActions.cubit.refresh();
  }

  void _onMessage(BuildContext context, PaywallState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.message) {
      case PaywallMessage.purchased:
        AppSnackBar.success(context, l10n.purchaseSuccess);
        context.pop();
      case PaywallMessage.restored:
        AppSnackBar.success(context, l10n.restoreSuccess);
        context.pop();
      case PaywallMessage.nothingToRestore:
        AppSnackBar.error(context, l10n.restoreNothing);
      case PaywallMessage.purchaseFailed:
        AppSnackBar.error(context, l10n.purchaseFailed);
      case PaywallMessage.unavailable:
        AppSnackBar.error(context, l10n.purchasesUnavailable);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Purchases go through Google Play only for now: on iOS the paywall
    // explains the plans but sells nothing.
    final sellsHere = defaultTargetPlatform != TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(AppIcons.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: BlocListener<PaywallCubit, PaywallState>(
        listenWhen: (a, b) => a.messageId != b.messageId,
        listener: _onMessage,
        child: BlocBuilder<ProCubit, ProState>(
          bloc: ProActions.cubit,
          builder: (context, pro) => BlocBuilder<PaywallCubit, PaywallState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _Hero(reason: widget.reason),
                  const SizedBox(height: 20),
                  _ComparisonTable(
                    status: pro.status,
                    loaded: pro.hasLoadedOnce,
                  ),
                  const SizedBox(height: 20),
                  if (pro.isPro)
                    _AlreadyPro(onManage: ProActions.manageSubscription)
                  else if (!sellsHere)
                    _Notice(l10n.proComingSoonIos)
                  else
                    _Plans(state: state),
                  const SizedBox(height: 16),
                  _Links(
                    isRestoring: state.isRestoring,
                    onRestore: sellsHere
                        ? context.read<PaywallCubit>().restore
                        : null,
                  ),
                  if (sellsHere && !pro.isPro && !state.isUnavailable) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.autoRenewDisclosure,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.reason});

  final PaywallReason reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final headline = switch (reason) {
      PaywallReason.upgrade => l10n.paywallHeadlineUpgrade,
      PaywallReason.scanLimit => l10n.paywallHeadlineScan,
      PaywallReason.chatLimit => l10n.paywallHeadlineChat,
      PaywallReason.productsLimit => l10n.paywallHeadlineProducts,
      PaywallReason.subscriptionsLimit => l10n.paywallHeadlineSubscriptions,
      PaywallReason.installmentsLimit => l10n.paywallHeadlineInstallments,
      PaywallReason.monthlySummary => l10n.paywallHeadlineSummary,
      PaywallReason.pdfReport => l10n.paywallHeadlinePdfReport,
      PaywallReason.voice => l10n.paywallHeadlineVoice,
    };
    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.pro,
                  color: Color(0xFFFFD966),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.sakkPro,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.paywallSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Free vs Pro. The free column shows the limits the server sent, so it
/// follows app_config without a release.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.status, required this.loaded});

  final ProStatus status;

  /// The server's limits have been read; until then they're unknown, not
  /// unlimited.
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Pro users get Pro's limits from the server, so the free column only
    // knows the real numbers for free users; '–' until then.
    final freeKnown = !status.isPro && loaded;

    // null from the server is unlimited (app_config).
    String count(int? n) =>
        n == null ? l10n.valueUnlimited : formatLocalizedInt(locale, n);
    String perDay(int? n) => n == null
        ? l10n.valueUnlimited
        : l10n.valuePerDay(formatLocalizedInt(locale, n));

    final rows = <(String, String, String)>[
      (
        l10n.featureProducts,
        freeKnown ? count(status.item(LimitedItem.products).limit) : '–',
        l10n.valueUnlimited,
      ),
      (
        l10n.featureSubscriptions,
        freeKnown ? count(status.item(LimitedItem.subscriptions).limit) : '–',
        l10n.valueUnlimited,
      ),
      (
        l10n.featureInstallments,
        freeKnown ? count(status.item(LimitedItem.installments).limit) : '–',
        l10n.valueUnlimited,
      ),
      (
        l10n.featureScans,
        freeKnown ? perDay(status.scan.limit) : '–',
        l10n.valueUnlimited,
      ),
      (
        l10n.featureChat,
        freeKnown ? perDay(status.chat.limit) : '–',
        l10n.valueUnlimited,
      ),
      (l10n.featureReminders, l10n.valueBasic, l10n.valueSmart),
      (l10n.featureSummary, '✕', '✓'),
      (l10n.featurePdfReport, '✕', '✓'),
      (l10n.featureVoice, '✕', '✓'),
    ];

    final header = textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.3),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Text(l10n.paywallFeature, style: header),
              Text(
                l10n.paywallFree,
                style: header,
                textAlign: TextAlign.center,
              ),
              Text(
                l10n.paywallPro,
                style: header?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          for (final (feature, free, pro) in rows)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(feature, style: textTheme.bodyMedium),
                ),
                Text(
                  free,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  pro,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.palette.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.state});

  final PaywallState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final cubit = context.read<PaywallCubit>();

    if (state.isUnavailable) return _Notice(l10n.purchasesUnavailable);

    // Placeholder plans shaped like the real ones while prices load.
    const placeholder = ProOffer(
      yearly: ProPackage(
        id: 'y',
        isYearly: true,
        price: 0,
        priceString: 'EGP 000.00',
        currencyCode: '',
        freeTrialDays: 7,
      ),
      monthly: ProPackage(
        id: 'm',
        isYearly: false,
        price: 0,
        priceString: 'EGP 00.00',
        currencyCode: '',
      ),
    );
    final offer = state.isLoading ? placeholder : state.offer!;
    final selected = state.isLoading ? placeholder.yearly : state.selected;
    final trialDays = selected?.freeTrialDays;
    final savings = offer.yearlySavingsPercent;

    return Skeletonizer(
      enabled: state.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offer.yearly != null)
            _PlanOption(
              title: l10n.planYearly,
              price: l10n.pricePerYear(offer.yearly!.priceString),
              badge: l10n.bestValue,
              savings: savings == null
                  ? null
                  : l10n.savePercent(formatLocalizedInt(locale, savings)),
              selected: selected == offer.yearly,
              onTap: () => cubit.select(yearly: true),
            ),
          if (offer.yearly != null && offer.monthly != null)
            const SizedBox(height: 10),
          if (offer.monthly != null)
            _PlanOption(
              title: l10n.planMonthly,
              price: l10n.pricePerMonth(offer.monthly!.priceString),
              selected: selected == offer.monthly,
              onTap: () => cubit.select(yearly: false),
            ),
          const SizedBox(height: 16),
          if (trialDays != null && selected != null) ...[
            Text(
              l10n.autoRenewTrialDisclosure(
                formatLocalizedInt(locale, trialDays),
                selected.isYearly
                    ? l10n.pricePerYear(selected.priceString)
                    : l10n.pricePerMonth(selected.priceString),
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: state.isBusy || state.isLoading
                  ? null
                  : cubit.purchase,
              child: state.isPurchasing
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      trialDays != null ? l10n.startFreeTrial : l10n.subscribe,
                    ),
            ),
          ),
          if (trialDays != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.freeTrialDays(
                  trialDays,
                  formatLocalizedInt(locale, trialDays),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.palette.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
    this.savings,
  });

  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final String? savings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shape = BorderRadius.circular(18);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(
            color: selected ? AppColors.primary : colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  selected ? AppIcons.successFilled : AppIcons.unpaid,
                  color: selected
                      ? AppColors.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: textTheme.titleMedium),
                          if (badge != null)
                            _Chip(text: badge!, color: AppColors.primary),
                          if (savings != null)
                            _Chip(
                              text: savings!,
                              color: context.palette.success,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AlreadyPro extends StatelessWidget {
  const _AlreadyPro({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(AppIcons.pro, color: Color(0xFFF2A900)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.alreadyPro,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onManage,
            child: Text(l10n.manageSubscription),
          ),
        ],
      ),
    );
  }
}

/// An info line in place of the plans (purchases unavailable, or not sold
/// on this platform yet).
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            AppIcons.info,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Links extends StatelessWidget {
  const _Links({required this.isRestoring, required this.onRestore});

  final bool isRestoring;

  /// Null hides the restore button (nothing to restore where nothing is sold).
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onRestore = this.onRestore;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onRestore != null)
          TextButton(
            onPressed: isRestoring ? null : onRestore,
            child: isRestoring
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.restorePurchases),
          ),
        TextButton(
          onPressed: () => context.push(AppRoutes.terms),
          child: Text(l10n.termsOfService),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.privacy),
          child: Text(l10n.privacyPolicy),
        ),
      ],
    );
  }
}
