import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/category/domain/entities/product_category.dart';
import 'package:sakk/features/products/data/models/product_model.dart';
import 'package:sakk/features/products/domain/entities/product_document.dart';
import 'package:sakk/features/products/domain/entities/warranty_claim.dart';

/// A products row as Supabase returns it with ProductModel.selectColumns.
Map<String, dynamic> row() => {
      'id': 'p1',
      'user_id': 'owner-1',
      'name': 'Fridge',
      'brand': 'LG',
      'price': 32000,
      'currency': 'EGP',
      'purchase_date': '2024-01-15',
      'warranty_months': 12,
      'image_url': null,
      'receipt_url': null,
      'store_name': 'Raya',
      'notes': null,
      'status': 'active',
      'category': 'appliances',
      'return_days': 14,
      'serial_number': 'SN-1',
      'invoice_number': 'INV-9',
      'product_warranties': [
        {'id': 'w1', 'provider': 'Raya extended', 'start_date': '2025-01-15', 'months': 24},
      ],
      'product_documents': [
        {'id': 'd1', 'kind': 'warranty_card', 'file_url': 'https://x/card', 'file_path': 'owner-1/documents/1.jpg', 'created_at': '2026-02-01T10:00:00Z'},
      ],
      'warranty_claims': [
        {'id': 'c1', 'issue': 'old', 'status': 'resolved', 'created_at': '2025-05-01T10:00:00Z'},
        {'id': 'c2', 'issue': 'Not cooling', 'status': 'in_repair', 'created_at': '2026-09-30T10:00:00Z'},
      ],
    };

void main() {
  test('reads a row with embedded extra warranties and claims', () {
    final p = ProductModel.fromJson(row());
    expect(p.category, ProductCategory.appliances);
    expect(p.returnDays, 14);
    expect((p.serialNumber, p.invoiceNumber), ('SN-1', 'INV-9'));
    expect(p.warrantyEndDate, DateTime(2027, 1, 15));
    expect(p.claims.map((c) => c.status), [ClaimStatus.inRepair, ClaimStatus.resolved]); // newest first
  });

  test('offline cache round-trips every field', () {
    final p = ProductModel.fromJson(row());
    final again = ProductModel.fromJson(jsonDecode(jsonEncode(p.toCacheJson())) as Map<String, dynamic>);
    expect(again, p);
  });

  test('rows saved before the new columns existed still load', () {
    final old = row()
      ..remove('return_days')
      ..remove('serial_number')
      ..remove('invoice_number')
      ..remove('product_warranties')
      ..remove('warranty_claims');
    final p = ProductModel.fromJson(old);
    expect(p.returnDays, isNull);
    expect(p.extraWarranties, isEmpty);
    expect(p.claims, isEmpty);
    expect(p.warrantyEndDate, DateTime(2025, 1, 15));
  });

  test('writes the database column names', () {
    final json = ProductModel.fromJson(row()).toInsertJson(userId: 'u1');
    expect(json['user_id'], 'u1');
    expect(json['store_name'], 'Raya');
    expect(json['return_days'], 14);
    expect(json['serial_number'], 'SN-1');
    expect(json['invoice_number'], 'INV-9');
    expect(json['purchase_date'], '2024-01-15');
  });

  test('claim status matches the database values', () {
    expect(ClaimStatus.inRepair.dbValue, 'in_repair');
    expect(ClaimStatusX.fromDb('in_repair'), ClaimStatus.inRepair);
    expect(ClaimStatusX.fromDb('nonsense'), ClaimStatus.submitted);
  });

  test('documents and the owner are read and kept in the cache', () {
    final p = ProductModel.fromJson(row());
    expect(p.ownerId, 'owner-1');
    expect(p.documents.single.kind, DocumentKind.warrantyCard);
    expect(p.documents.single.path, 'owner-1/documents/1.jpg');
    expect(DocumentKind.productPhoto.dbValue, 'product_photo');
    expect(DocumentKindX.fromDb('nonsense'), DocumentKind.other);
  });

  test('only the owner may edit; products cached before ownerId stay editable', () {
    final p = ProductModel.fromJson(row());
    expect(p.isOwnedBy('owner-1'), isTrue);
    expect(p.isOwnedBy('household-member'), isFalse);
    expect(ProductModel.fromJson(row()..remove('user_id')).isOwnedBy('anyone'), isTrue);
  });
}
