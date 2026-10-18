import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/pro_cubit.dart';
import '../pro_actions.dart';

/// Home's way into the monthly summary. Free users see a lock and get the
/// paywall in its place (the route decides).
class MonthlySummaryTile extends StatelessWidget {
  const MonthlySummaryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final pro = ProActions.maybeCubit;
    if (pro == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ProCubit, ProState>(
      bloc: pro,
      buildWhen: (a, b) => a.isPro != b.isPro,
      builder: (context, state) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => context.push(AppRoutes.monthlySummary),
        child: Row(
          children: [
            Icon(AppIcons.monthlySummary, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.monthlySummary, style: Theme.of(context).textTheme.titleSmall)),
            if (!state.isPro) ...[
              Icon(AppIcons.locked, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(l10n.paywallPro, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: 8),
            ],
            Icon(AppIcons.chevronForward, size: 18, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
