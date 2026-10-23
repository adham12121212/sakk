import 'package:equatable/equatable.dart';

import '../../../category/domain/entities/product_category.dart';

class ScannedReceiptData extends Equatable {
  final String? productName;
  final String? brand;
  final double? price;
  final DateTime? purchaseDate;
  final int? warrantyMonths;
  final String? store;
  final String? receiptImageUrl;
  final String? imageUrl;
  final ProductCategory? category;
  final String? serialNumber;
  final String? invoiceNumber;

  /// Set when the receipt's price is in another currency; [price] is then
  /// null because the app stores EGP only.
  final double? foreignPrice;
  final String? foreignCurrency;

  /// Storage path of the uploaded photo, so it can be deleted if the user
  /// leaves without saving.
  final String? receiptPath;

  final double confidence;

  const ScannedReceiptData({
    this.productName,
    this.brand,
    this.price,
    this.purchaseDate,
    this.warrantyMonths,
    this.store,
    this.receiptImageUrl,
    this.confidence = 0.0,
    this.imageUrl,
    this.category,
    this.serialNumber,
    this.invoiceNumber,
    this.foreignPrice,
    this.foreignCurrency,
    this.receiptPath,
  });

  ScannedReceiptData copyWith({
    String? productName,
    String? brand,
    double? price,
    DateTime? purchaseDate,
    int? warrantyMonths,
    String? store,
    String? receiptImageUrl,
    String? imageUrl,
    double? confidence,
    ProductCategory? category,
    String? serialNumber,
    String? invoiceNumber,
    double? foreignPrice,
    String? foreignCurrency,
    String? receiptPath,
  }) {
    return ScannedReceiptData(
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      store: store ?? this.store,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      confidence: confidence ?? this.confidence,
      category: category ?? this.category,
      serialNumber: serialNumber ?? this.serialNumber,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      foreignPrice: foreignPrice ?? this.foreignPrice,
      foreignCurrency: foreignCurrency ?? this.foreignCurrency,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }

  @override
  List<Object?> get props => [
    productName,
    brand,
    price,
    purchaseDate,
    warrantyMonths,
    store,
    receiptImageUrl,
    confidence,
    imageUrl,
    category,
    serialNumber,
    invoiceNumber,
    foreignPrice,
    foreignCurrency,
    receiptPath,
  ];
}
