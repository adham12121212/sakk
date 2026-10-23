import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';

class ConfidenceBanner extends StatelessWidget {
  const ConfidenceBanner({super.key, required this.confidence});

  final double confidence;

  static const _highThreshold = 0.8;
  static const _mediumThreshold = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final level = _levelFor(context, l10n, confidence);
    final percent = (confidence * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: level.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(level.icon, color: level.foreground, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(text: l10n.confidenceScoreLabel),
                      TextSpan(
                        text: '$percent%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: level.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (level.subtext != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    level.subtext!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ConfidenceLevel _levelFor(
    BuildContext context,
    AppLocalizations l10n,
    double confidence,
  ) {
    final p = context.palette;
    if (confidence >= _highThreshold) {
      return _ConfidenceLevel(
        foreground: p.success,
        background: p.successContainer,
        icon: AppIcons.successFilled,
      );
    }
    if (confidence >= _mediumThreshold) {
      return _ConfidenceLevel(
        foreground: p.warning,
        background: p.warningContainer,
        icon: AppIcons.info,
        subtext: l10n.doubleCheckFieldsBelow,
      );
    }
    return _ConfidenceLevel(
      foreground: p.danger,
      background: p.dangerContainer,
      icon: AppIcons.error,
      subtext: l10n.lowConfidenceWarning,
    );
  }
}

class _ConfidenceLevel {
  const _ConfidenceLevel({
    required this.foreground,
    required this.background,
    required this.icon,
    this.subtext,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
  final String? subtext;
}
