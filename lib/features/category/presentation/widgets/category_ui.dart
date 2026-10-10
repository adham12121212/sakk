import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product_category.dart';
import '../../../../core/theme/app_icons.dart';


class CategoryUi {
  CategoryUi._();

  static IconData icon(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return AppIcons.electronics;
      case ProductCategory.appliances:
        return AppIcons.appliances;
      case ProductCategory.furniture:
        return AppIcons.furniture;
      case ProductCategory.vehicles:
        return AppIcons.vehicles;
      case ProductCategory.accessories:
        return AppIcons.accessories;
      case ProductCategory.other:
        return AppIcons.otherCategory;
    }
  }

  static Color color(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return const Color(0xFF3B82F6);
      case ProductCategory.appliances:
        return const Color(0xFF22C55E);
      case ProductCategory.furniture:
        return const Color(0xFF8B5CF6);
      case ProductCategory.vehicles:
        return const Color(0xFFEF4444);
      case ProductCategory.accessories:
        return const Color(0xFFF59E0B);
      case ProductCategory.other:
        return const Color(0xFF9CA3AF);
    }
  }

  static String label(BuildContext  context, ProductCategory category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case ProductCategory.electronics:
        return l10n.electronics;
      case ProductCategory.appliances:
        return l10n.appliances;
      case ProductCategory.furniture:
        return l10n.furniture;
      case ProductCategory.vehicles:
        return l10n.vehicles;
      case ProductCategory.accessories:
        return l10n.accessories;
      case ProductCategory.other:
        return l10n.other;
    }
  }


}