import 'package:flutter/material.dart';

import '../../domain/entities/product_category.dart';


class CategoryUi {
  CategoryUi._();

  static IconData icon(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return Icons.smartphone_rounded;
      case ProductCategory.appliances:
        return Icons.kitchen_rounded;
      case ProductCategory.furniture:
        return Icons.chair_rounded;
      case ProductCategory.vehicles:
        return Icons.directions_car_rounded;
      case ProductCategory.accessories:
        return Icons.watch_rounded;
      case ProductCategory.other:
        return Icons.category_rounded;
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

  static String label(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return 'Electronics';
      case ProductCategory.appliances:
        return 'Appliances';
      case ProductCategory.furniture:
        return 'Furniture';
      case ProductCategory.vehicles:
        return 'Vehicles';
      case ProductCategory.accessories:
        return 'Accessories';
      case ProductCategory.other:
        return 'Other';
    }
  }
}