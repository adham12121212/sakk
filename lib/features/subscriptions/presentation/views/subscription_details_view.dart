import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../util/subscription_category_ui.dart';
import '../util/subscription_format.dart';
import '../widgets/subscription_logo.dart';
import 'subscription_form_view.dart';

/// One subscription: what it costs, when it renews, the plan, how it's paid
/// and notes. Edit is in the app bar.
class SubscriptionDetailsView extends StatelessWidget {
  const SubscriptionDetailsView({super.key, required this.subscription});

  /// As it was when opened; the shared list's newer version wins, so an
  /// edit shows here straight away.
  final UserSubscription subscription;

  Future<void> _edit(BuildContext context, UserSubscription current) async {
    final cubit = context.read<SubscriptionsCubit>();
    await context.push(
      AppRoutes.subscriptionForm,
      extra: SubscriptionFormArgs.edit(current),
    );
    // Deleted from the form: nothing left to show.
    if (context.mounted &&
        !cubit.state.subscriptions.any((s) => s.id == subscription.id)) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<
      SubscriptionsCubit,
      SubscriptionsState,
      UserSubscription
    >(
      selector: (state) => state.subscriptions.firstWhere(
        (s) => s.id == subscription.id,
        orElse: () => subscription,
      ),
      builder: (context, current) {
        final today = DateTime.now();
        return Scaffold(
          appBar: AppBar(
            title: Text(current.name),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: l10n.edit,
                icon: const Icon(AppIcons.edit),
                onPressed: () => _edit(context, current),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Header(subscription: current, today: today),
                const SizedBox(height: 16),
                _Price(subscription: current),
                const SizedBox(height: 16),
                _Details(subscription: current, today: today),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The logo, the name, its category and when it renews.
class _Header extends StatelessWidget {
  const _Header({required this.subscription, required this.today});

  final UserSubscription subscription;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final days = subscription.daysLeft(today);
    final soon = days >= 0 && days <= 3;
    final chipColor = soon
        ? context.palette.warning
        : Theme.of(context).colorScheme.primary;

    return AppCard(
      child: Row(
        children: [
          SubscriptionLogo(
            name: subscription.name,
            logoUrl: subscription.logoUrl,
            domain: subscription.domain,
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subscription.name, style: textTheme.titleLarge),
                Text(
                  SubscriptionCategoryUi.label(context, subscription.category),
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    child: Text(
                      renewalLabel(l10n, days),
                      style: TextStyle(
                        color: chipColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The price per cycle, large; for a yearly one, what that is a month.
class _Price extends StatelessWidget {
  const _Price({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final yearly = subscription.billingCycle == BillingCycle.yearly;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.price, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  formatPricePerCycle(
                    context,
                    subscription.price,
                    subscription.currency,
                    subscription.billingCycle,
                  ),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (yearly)
                  Text(
                    l10n.subscriptionMonthlyEquivalent(
                      formatMoney(
                        context,
                        subscription.monthlyCost,
                        subscription.currency,
                      ),
                    ),
                    style: textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            yearly ? l10n.billingYearly : l10n.billingMonthly,
            style: textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Next renewal, plan, payment method and notes, each on its own row when
/// there is one.
class _Details extends StatelessWidget {
  const _Details({required this.subscription, required this.today});

  final UserSubscription subscription;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final tag = locale.languageCode == 'ar' ? 'ar_EG' : locale.toLanguageTag();
    final plan = subscription.planName;
    final payment = subscription.paymentMethod;
    final notes = subscription.notes;
    final rows = [
      (
        l10n.nextRenewal,
        DateFormat.yMMMd(tag).format(subscription.nextRenewalDate),
      ),
      if (plan != null && plan.isNotEmpty && plan != subscription.name)
        (l10n.subscriptionPlan, plan),
      if (payment != null) (l10n.subscriptionPaymentMethod, payment),
      if (notes != null) (l10n.notes, notes),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final (i, (label, value)) in rows.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    SelectableText(
                      value,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
