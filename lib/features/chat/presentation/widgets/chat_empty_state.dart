import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'ai_avatar.dart';
import '../../../../core/theme/app_icons.dart';

/// First-open state: gradient AI avatar, short intro and tappable suggestions.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key, required this.onSuggestionTap, required this.l10n});

  final ValueChanged<String> onSuggestionTap;
  final AppLocalizations l10n;

  List<String> get _suggestions => [
        l10n.howdoIaddanewproduct,
        l10n.whatshouldIdoifaproductbreaks,
      ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AiAvatar(size: 76),
                  const SizedBox(height: 20),
                  Text(l10n.askmeanything, textAlign: TextAlign.center, style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    l10n.icanhelpwithyourproductswarrantiesandpurchases,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  for (final s in _suggestions) ...[
                    AppCard(
                      onTap: () => onSuggestionTap(s),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(AppIcons.chat, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(child: Text(s, style: textTheme.bodyMedium)),
                          Icon(AppIcons.forward, size: 18, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
