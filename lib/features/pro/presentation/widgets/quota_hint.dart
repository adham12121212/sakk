import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/pro_limit.dart';
import '../cubit/pro_cubit.dart';
import '../pro_actions.dart';

/// "2 scans left today" / "3 messages left today" for free users; tapping
/// it opens the paywall. Nothing for Pro users or before the plan is known.
class QuotaHint extends StatelessWidget {
  const QuotaHint({super.key, required this.type});

  final QuotaType type;

  @override
  Widget build(BuildContext context) {
    final pro = ProActions.maybeCubit;
    if (pro == null) return const SizedBox.shrink();
    return BlocBuilder<ProCubit, ProState>(
      bloc: pro,
      builder: (context, state) {
        final remaining = state.status.quota(type).remaining;
        if (state.isPro || !state.hasLoadedOnce || remaining == null) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context)!;
        final text = formatLocalizedInt(
          Localizations.localeOf(context),
          remaining,
        );
        final label = type == QuotaType.scan
            ? l10n.scansLeftToday(remaining, text)
            : l10n.chatMessagesLeftToday(remaining, text);
        final color = remaining == 0
            ? context.palette.warning
            : Theme.of(context).colorScheme.onSurfaceVariant;

        return Semantics(
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => ProActions.openPaywall(
              context,
              type == QuotaType.scan
                  ? PaywallReason.scanLimit
                  : PaywallReason.chatLimit,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == QuotaType.scan ? AppIcons.scan : AppIcons.ai,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
