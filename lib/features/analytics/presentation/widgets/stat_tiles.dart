import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/util/localized_number.dart';
import '../../../../core/util/warranty_progress_color.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/cubit/product_state.dart';

/// Three small tiles: how many products, how many still under warranty and
/// how many are expiring. The expiring tile is tinted while there are any.
class StatTiles extends StatelessWidget {
  const StatTiles({super.key, required this.state, required this.l10n});

  final ProductsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading = state.isLoading && state.products.isEmpty;
    final locale = Localizations.localeOf(context);
    String n(int v) => formatLocalizedInt(locale, isInitialLoading ? 0 : v);
    final expiringColor = warrantyStatusColor(context, WarrantyStatus.expiring);

    return Skeletonizer(
      enabled: isInitialLoading,
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              value: n(state.total),
              label: l10n.products,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Tile(
              value: n(state.active),
              label: l10n.active,
              color: warrantyStatusColor(context, WarrantyStatus.active),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Tile(
              value: n(state.expiring),
              label: l10n.expiring,
              color: expiringColor,
              tinted: !isInitialLoading && state.expiring > 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    required this.color,
    this.tinted = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: tinted
          ? Color.alphaBlend(
              color.withValues(alpha: 0.14),
              Theme.of(context).colorScheme.surface,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
