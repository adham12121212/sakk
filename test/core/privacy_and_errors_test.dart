import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/error/user_facing_error.dart';
import 'package:sakk/core/util/pii_masker.dart';
import 'package:sakk/features/products/data/product_data_source/product_data_source.dart';
import 'package:sakk/features/products/presentation/util/products_csv_export.dart';
import 'package:sakk/l10n/app_localizations_en.dart';

void main() {
  group('PiiMasker.scrub (before anything is sent to Crashlytics)', () {
    test('removes emails, signed-link tokens and JWTs', () {
      const url =
          'https://x.supabase.co/storage/v1/object/sign/receipts/u1/1.jpg?token=eyJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJ4In0.sig-abc_123';
      final out = PiiMasker.scrub('failed for ahmed@mail.com at $url');
      expect(out, isNot(contains('ahmed@mail.com')));
      expect(out, isNot(contains('eyJ')));
      expect(out, contains('?token=[token]'));
      expect(out, contains('/receipts/u1/1.jpg'));
    });

    test('a bare JWT is removed too', () {
      expect(PiiMasker.scrub('Bearer eyJa.eyJb.c_d'), 'Bearer [token]');
    });
  });

  group('csvCell', () {
    test('quotes commas, quotes and line breaks', () {
      expect(csvCell('a,b'), '"a,b"');
      expect(csvCell('55" TV'), '"55"" TV"');
      expect(csvCell('line1\nline2'), '"line1\nline2"');
      expect(csvCell(null), '');
      expect(csvCell(12), '12');
    });

    test('text starting like a formula is neutralised', () {
      expect(csvCell('=HYPERLINK("x")'), '"\'=HYPERLINK(""x"")"');
      expect(csvCell('+20 100'), "'+20 100");
    });
  });

  group('userFacingError', () {
    final l10n = AppLocalizationsEn();

    test('maps known codes and hides technical messages', () {
      expect(
        userFacingError(l10n, NetworkFailure.noConnectionMessage),
        l10n.errorNoInternet,
      );
      expect(
        userFacingError(l10n, ProductDataSourceImpl.unreadableReceipt),
        l10n.scanUnreadable,
      );
      expect(
        userFacingError(l10n, ProductDataSourceImpl.aiBusy),
        l10n.scanBusy,
      );
      expect(
        userFacingError(l10n, ProductDataSourceImpl.pdfUnreadable),
        l10n.pdfUnreadable,
      );
      expect(
        userFacingError(l10n, 'FunctionsHttpException(status: 500)'),
        l10n.errorGeneric,
      );
    });
  });
}
