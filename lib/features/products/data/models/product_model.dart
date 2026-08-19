import '../../../category/domain/entities/product_category.dart';
import '../../domain/enties/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.brand,
    super.price,
    super.currency,
    required super.purchaseDate,
    required super.warrantyMonths,
    super.imageUrl,
    super.receiptUrl,
    super.store,
    super.notes,
    super.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      warrantyMonths: json['warranty_months'] as int,
      imageUrl: json['image_url'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      store: json['store_name'] as String?,
      notes: json['notes'] as String?,
      category: ProductCategoryX.fromName(json['category'] as String?),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return _sharedFields();
  }

  Map<String, dynamic> _sharedFields() {
    return {
      'name': name,
      'brand': brand,
      'price': price,
      'currency': currency,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'warranty_months': warrantyMonths,
      'image_url': imageUrl,
      'receipt_url': receiptUrl,
      'store_name': store,
      'notes': notes,
      'status': status.name,
      'category': category.name,
    };
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'name': name,
      'brand': brand,
      'price': price,
      'currency': currency,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'warranty_months': warrantyMonths,
      'image_url': imageUrl,
      'receipt_url': receiptUrl,
      'store_name': store,
      'notes': notes,
      'status': status.name,
      'category': category.name,
    };
  }
}