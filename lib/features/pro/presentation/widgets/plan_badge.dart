import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pro_status.dart';
import '../cubit/pro_cubit.dart';
import '../pro_actions.dart';

enum PlanBadgeSize { regular, small }

/// The user's plan as a pill: grey "Free", gold "Sakk Pro" (a star for
/// yearly), "Pro – Trial" with the days left, or an amber "Payment issue".
///
/// [PlanBadge.live] follows [ProCubit], so it changes the moment a purchase,
/// trial or expiry is known, and taps through: Free opens the paywall, a
/// payment issue opens Google Play's subscription page.
class PlanBadge extends StatelessWidget {
  const PlanBadge({
    super.key,
    required this.status,
    this.size = PlanBadgeSize.regular,
    this.onTap,
    this.now,
  });

  /// The badge for the signed-in user, kept up to date.
  static Widget live({PlanBadgeSize size = PlanBadgeSize.regular}) => _LivePlanBadge(size: size);

  final ProStatus status;
  final PlanBadgeSize size;
  final VoidCallback? onTap;

  /// For tests; the trial's days left count from now.
  final DateTime? now;

  // Same gold in both themes: it sits on the brand gradient and on cards.
  static const _goldGradient = [Color(0xFFFFD966), Color(0xFFF2A900)];
  static const _onGold = Color(0xFF3D2A00);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final small = size == PlanBadgeSize.small;

    final plan = status.plan;
    final (label, icon) = switch (plan) {
      PlanKind.free => (l10n.planBadgeFree, null),
      PlanKind.monthly => (l10n.planBadgePro, AppIcons.pro),
      PlanKind.yearly => (l10n.planBadgeYearly, null),
      PlanKind.trial => (_trialLabel(l10n, locale), AppIcons.pro),
      PlanKind.billingIssue => (l10n.planBadgeBillingIssue, AppIcons.warning),
    };
    final isGold = plan == PlanKind.monthly || plan == PlanKind.yearly;
    final foreground = switch (plan) {
      PlanKind.free => colorScheme.onSurfaceVariant,
      PlanKind.billingIssue => palette.warning,
      PlanKind.trial => Theme.of(context).brightness == Brightness.dark ? _goldGradient.first : const Color(0xFF8A5A00),
      _ => _onGold,
    };
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: isGold ? const LinearGradient(colors: _goldGradient) : null,
      color: switch (plan) {
        PlanKind.free => colorScheme.surfaceContainerHighest,
        PlanKind.billingIssue => palette.warningContainer,
        PlanKind.trial => _goldGradient.last.withValues(alpha: 0.16),
        _ => null,
      },
      // The yearly plan's "distinct touch": a white inner ring on the gold.
      border: switch (plan) {
        PlanKind.yearly => Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
        PlanKind.trial => Border.all(color: _goldGradient.last.withValues(alpha: 0.6)),
        _ => null,
      },
      boxShadow: isGold ? const [BoxShadow(color: Color(0x33F2A900), blurRadius: 8, offset: Offset(0, 2))] : null,
    );

    final badge = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: small ? 8 : 12, vertical: small ? 2 : 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: small ? 12 : 15, color: foreground),
              SizedBox(width: small ? 3 : 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: small ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return Semantics(label: label, child: ExcludeSemantics(child: badge));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // At least 32 tall to tap, without making the pill itself bigger.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Center(widthFactor: 1, child: badge),
        ),
      ),
    );
  }

  String _trialLabel(AppLocalizations l10n, Locale locale) {
    final days = status.trialDaysLeft(now ?? DateTime.now());
    if (days == null) return l10n.planBadgeTrial;
    return '${l10n.planBadgeTrial} · ${l10n.planBadgeTrialDaysLeft(days, formatLocalizedInt(locale, days))}';
  }
}

class _LivePlanBadge extends StatelessWidget {
  const _LivePlanBadge({required this.size});

  final PlanBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final pro = ProActions.maybeCubit;
    if (pro == null) return const SizedBox.shrink();
    return BlocBuilder<ProCubit, ProState>(
      bloc: pro,
      builder: (context, state) {
        // Nothing until the plan is known, so a Pro user never sees "Free"
        // flash first.
        if (!state.hasLoadedOnce && !state.isPro) return const SizedBox.shrink();
        final plan = state.status.plan;
        return PlanBadge(
          status: state.status,
          size: size,
          onTap: switch (plan) {
            PlanKind.free => () => ProActions.openPaywall(context),
            PlanKind.billingIssue => ProActions.manageSubscription,
            _ => null,
          },
        );
      },
    );
  }
}
