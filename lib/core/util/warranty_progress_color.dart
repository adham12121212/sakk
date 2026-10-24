import 'package:flutter/material.dart';

import '../../features/products/domain/entities/product_entity.dart';
import '../theme/app_palette.dart';

/// Colour of a warranty's progress bar or ring, by its status: green while
/// active, yellow once expiring, red when expired.
Color warrantyStatusColor(BuildContext context, WarrantyStatus status) {
  final palette = context.palette;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    WarrantyStatus.active => palette.success,
    WarrantyStatus.expiring =>
      dark ? const Color(0xFFFACC15) : const Color(0xFFEAB308),
    WarrantyStatus.expired => palette.danger,
  };
}
