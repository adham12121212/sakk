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
  ];
}