import 'package:equatable/equatable.dart';

import '../../../category/domain/entities/product_category.dart';

enum WarrantyStatus { active, expiring, expired }

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? brand;
  final double? price;
  final String currency;

  final DateTime purchaseDate;
  final int warrantyMonths;

  final String? imageUrl;
  final String? receiptUrl;

  final String? store;
  final String? notes;

  final ProductCategory category;

  const ProductEntity({
    required this.id,
    required this.name,
    this.brand,
    this.price,
    this.currency = 'EGP',
    required this.purchaseDate,
    required this.warrantyMonths,
    this.imageUrl,
    this.receiptUrl,
    this.store,
    this.notes,
    this.category = ProductCategory.other,
  });

  static const int expiringSoonMonths = 3;

  DateTime get warrantyEndDate => DateTime(
    purchaseDate.year,
    purchaseDate.month + warrantyMonths,
    purchaseDate.day,
  );

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);


  int get daysRemaining {
    final today = _dateOnly(DateTime.now());
    final endDate = _dateOnly(warrantyEndDate);
    return endDate.difference(today).inDays;
  }



  WarrantyStatus get status {
    if (daysRemaining <= 0) {
      return WarrantyStatus.expired;
    }

    final expiringThresholdDays = expiringSoonMonths * 30;

    if (daysRemaining <= expiringThresholdDays) {
      return WarrantyStatus.expiring;
    }

    return WarrantyStatus.active;
  }

  bool get isExpired => status == WarrantyStatus.expired;
  bool get isExpiring => status == WarrantyStatus.expiring;
  bool get isActive => status == WarrantyStatus.active;

  @override
  List<Object?> get props => [
    id,
    name,
    brand,
    price,
    currency,
    purchaseDate,
    warrantyMonths,
    warrantyEndDate,
    imageUrl,
    receiptUrl,
    store,
    notes,
    status,
    category,
  ];
}