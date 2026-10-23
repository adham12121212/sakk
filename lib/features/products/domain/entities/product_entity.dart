import 'package:equatable/equatable.dart';

import '../../../category/domain/entities/product_category.dart';
import 'extra_warranty.dart';
import 'product_document.dart';
import 'warranty_claim.dart';

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

  /// Days after purchase the store accepts a return; null when not tracked.
  final int? returnDays;

  /// Who added the product. With family sharing, household members see each
  /// other's products, but only the owner can change them. Null for products
  /// cached before this field existed (always the user's own).
  final String? ownerId;

  /// Stores ask for these when you make a warranty claim.
  final String? serialNumber;
  final String? invoiceNumber;

  /// Warranties on top of the manufacturer's (e.g. extended from the store).
  final List<ExtraWarranty> extraWarranties;

  final List<WarrantyClaim> claims;

  /// Warranty card, product photo, manual... (the receipt is [receiptUrl]).
  final List<ProductDocument> documents;

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
    this.returnDays,
    this.ownerId,
    this.serialNumber,
    this.invoiceNumber,
    this.extraWarranties = const [],
    this.claims = const [],
    this.documents = const [],
  });

  static const int expiringSoonMonths = 3;

  DateTime get manufacturerWarrantyEndDate => DateTime(
    purchaseDate.year,
    purchaseDate.month + warrantyMonths,
    purchaseDate.day,
  );

  /// When the product stops being covered: the latest end date across the
  /// manufacturer's warranty and any extra ones. Status, days left, the
  /// ring and reminders all follow this date.
  DateTime get warrantyEndDate {
    var end = manufacturerWarrantyEndDate;
    for (final extra in extraWarranties) {
      if (extra.endDate.isAfter(end)) end = extra.endDate;
    }
    return end;
  }

  /// Last day the store takes the product back, or null when not tracked.
  DateTime? get returnByDate => returnDays == null
      ? null
      : DateTime(
          purchaseDate.year,
          purchaseDate.month,
          purchaseDate.day + returnDays!,
        );

  /// Days until [returnByDate] (0 on the last day, negative once it passed),
  /// or null when no return window is tracked.
  int? get daysToReturn {
    final returnBy = returnByDate;
    if (returnBy == null) return null;
    return _dateOnly(returnBy).difference(_dateOnly(DateTime.now())).inDays;
  }

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

  /// Whether [userId] may edit or delete this product (household members
  /// only view each other's).
  bool isOwnedBy(String? userId) => ownerId == null || ownerId == userId;

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
    returnDays,
    ownerId,
    serialNumber,
    invoiceNumber,
    extraWarranties,
    claims,
    documents,
  ];
}
