import '../../../category/domain/entities/product_category.dart';
import '../../domain/enties/extra_warranty.dart';
import '../../domain/enties/product_document.dart';
import '../../domain/enties/product_entity.dart';
import '../../domain/enties/warranty_claim.dart';

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
    super.returnDays,
    super.ownerId,
    super.serialNumber,
    super.invoiceNumber,
    super.extraWarranties,
    super.claims,
    super.documents,
  });

  /// Columns to select so a product row arrives with its extra warranties
  /// and claims embedded (PostgREST follows the product_id foreign keys).
  static const selectColumns = '*, product_warranties(*), warranty_claims(*), product_documents(*)';

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
      returnDays: json['return_days'] as int?,
      ownerId: json['user_id'] as String?,
      serialNumber: json['serial_number'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      extraWarranties: [
        for (final w in (json['product_warranties'] as List? ?? const []).cast<Map<String, dynamic>>())
          ExtraWarranty(
            id: w['id'] as String,
            provider: w['provider'] as String,
            startDate: DateTime.parse(w['start_date'] as String),
            months: w['months'] as int,
          ),
      ]..sort((a, b) => a.startDate.compareTo(b.startDate)),
      claims: [
        for (final c in (json['warranty_claims'] as List? ?? const []).cast<Map<String, dynamic>>())
          WarrantyClaim(
            id: c['id'] as String,
            issue: c['issue'] as String,
            status: ClaimStatusX.fromDb(c['status'] as String?),
            createdAt: DateTime.parse(c['created_at'] as String),
          ),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      documents: [
        for (final d in (json['product_documents'] as List? ?? const []).cast<Map<String, dynamic>>())
          ProductDocument(
            id: d['id'] as String,
            kind: DocumentKindX.fromDb(d['kind'] as String?),
            url: d['file_url'] as String,
            path: d['file_path'] as String,
            createdAt: DateTime.parse(d['created_at'] as String),
          ),
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
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
      'return_days': returnDays,
      'serial_number': serialNumber,
      'invoice_number': invoiceNumber,
    };
  }

  /// Full row for the offline cache; round-trips through [ProductModel.fromJson].
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'user_id': ownerId,
        ..._sharedFields(),
        'product_warranties': [
          for (final w in extraWarranties)
            {
              'id': w.id,
              'provider': w.provider,
              'start_date': _isoDate(w.startDate),
              'months': w.months,
            },
        ],
        'warranty_claims': [
          for (final c in claims)
            {
              'id': c.id,
              'issue': c.issue,
              'status': c.status.dbValue,
              'created_at': c.createdAt.toIso8601String(),
            },
        ],
        'product_documents': [
          for (final d in documents)
            {
              'id': d.id,
              'kind': d.kind.dbValue,
              'file_url': d.url,
              'file_path': d.path,
              'created_at': d.createdAt.toIso8601String(),
            },
        ],
      };

  static String _isoDate(DateTime d) => d.toIso8601String().split('T').first;

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
      'return_days': returnDays,
      'serial_number': serialNumber,
      'invoice_number': invoiceNumber,
    };
  }
}