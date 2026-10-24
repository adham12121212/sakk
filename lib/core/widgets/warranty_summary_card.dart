import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_palette.dart';
import '../util/localized_number.dart';
import 'app_card.dart';
import '../../l10n/app_localizations.dart';

/// The warranty summary (Home, Products): how many products are tracked, a count each
/// for active, expiring and expired, and a bar split by those counts.
/// Tapping opens Products.
class WarrantySummaryCard extends StatelessWidget {
  const WarrantySummaryCard({
    super.key,
    required this.active,
    required this.expiring,
    required this.expired,
    this.onTap,
  });

  final int active;
  final int expiring;
  final int expired;
  final VoidCallback? onTap;

  int get total => active + expiring + expired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    String n(int value) => formatLocalizedInt(locale, value);

    final segments = [
      (active, palette.success, l10n.statActive),
      (expiring, palette.warning, l10n.statExpiring),
      (expired, palette.danger, l10n.statExpired),
    ];

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                n(total),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.statProducts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  AppIcons.chevronForward,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SplitBar(
            segments: [for (final (c, color, _) in segments) (c, color)],
            empty: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final (count, color, label) in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: n(count),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' $label'),
                        ],
                      ),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A rounded bar with one part per non-empty segment, sized by its count;
/// just the empty track when there's nothing yet.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.segments, required this.empty});

  final List<(int, Color)> segments;
  final Color empty;

  @override
  Widget build(BuildContext context) {
    final shown = segments.where((s) => s.$1 > 0).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: shown.isEmpty
            ? ColoredBox(color: empty)
            : Row(
                // Full height: an empty ColoredBox is otherwise 0 tall.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (count, color)) in shown.indexed) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: count,
                      child: ColoredBox(color: color),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
