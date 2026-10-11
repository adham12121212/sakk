

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product_category.dart';
import 'category_ui.dart';
import '../../../../core/theme/app_icons.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, 
    required this.category,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final ProductCategory category;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = CategoryUi.color(category);
    final colorScheme = Theme.of(context).colorScheme;


    final textTheme = Theme.of(context).textTheme;
    final shape = BorderRadius.circular(20);

    return Semantics(
      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: shape,
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: AppCard(
          onTap: onTap,
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(CategoryUi.icon(category), color: color, size: 22),
                  ),
                  const Spacer(),
                  if (isSelected) Icon(AppIcons.successFilled, color: colorScheme.primary, size: 22),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                CategoryUi.label(context, category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? l10n.product : l10n.products}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}