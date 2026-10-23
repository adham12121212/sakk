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

  test('a stored path is its own path', () {
    const path = '0b4c5a6e-1f2d-4e3a-9b8c-7d6e5f4a3b2c/documents/2.png';
    expect(ProductDataSourceImpl.receiptPathFromUrl(path), path);
    // Not a user's folder.
    expect(ProductDataSourceImpl.receiptPathFromUrl('u1/1.jpg'), isNull);
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

  test('a signed receipt link is written back as its path; other links stay', () {
    const uid = '0b4c5a6e-1f2d-4e3a-9b8c-7d6e5f4a3b2c';
    expect(
      ProductDataSourceImpl.withStoredPaths({
        'name': 'TV',
        'receipt_url':
            'https://x.supabase.co/storage/v1/object/sign/receipts/$uid/1.jpg?token=abc',
        'image_url': 'https://example.com/tv.jpg',
      }),
      {
        'name': 'TV',
        'receipt_url': '$uid/1.jpg',
        'image_url': 'https://example.com/tv.jpg',
      },
    );
  });
}
