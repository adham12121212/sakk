import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/products/data/product_data_source/product_data_source.dart';

void main() {
  test('storage path from a signed receipt URL', () {
    expect(
      ProductDataSourceImpl.receiptPathFromUrl(
        'https://x.supabase.co/storage/v1/object/sign/receipts/u1/1791652122923.jpg?token=abc',
      ),
      'u1/1791652122923.jpg',
    );
    expect(
      ProductDataSourceImpl.receiptPathFromUrl(
        'https://x.supabase.co/storage/v1/object/sign/receipts/u1/documents/2.png?token=t',
      ),
      'u1/documents/2.png',
    );
  });

  test('other URLs give no path, so nothing else is ever deleted', () {
    expect(
      ProductDataSourceImpl.receiptPathFromUrl(
        'https://x.supabase.co/storage/v1/object/public/avatars/u1/a.jpg',
      ),
      isNull,
    );
    expect(
      ProductDataSourceImpl.receiptPathFromUrl(
        'https://example.com/receipt.jpg',
      ),
      isNull,
    );
    expect(ProductDataSourceImpl.receiptPathFromUrl('not a url'), isNull);
  });
}
