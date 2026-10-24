import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/paper.dart';
import '../util/paper_format.dart';
import '../util/paper_ui.dart';

/// List row: the kind's icon, the name and when it expires.
class PaperTile extends StatelessWidget {
  const PaperTile({
    super.key,
    required this.paper,
    required this.today,
    this.onTap,
  });

  final Paper paper;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = PaperUi.color(paper.kind);
    final statusColor = paperStatusColor(context, paper.status(today));
    final kindName = PaperUi.kindName(l10n, paper.kind);
    final name = PaperUi.name(l10n, paper);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(PaperUi.icon(paper.kind), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      if (name != kindName) TextSpan(text: '$kindName · '),
                      TextSpan(
                        text: paperExpiryLabel(context, paper, today),
                        style: statusColor == null
                            ? null
                            : TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            AppIcons.chevronForward,
            size: 20,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
