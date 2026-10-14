import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/util/validators.dart';

void main() {
  group('AppValidators.normalizeEmail', () {
    test('strips invisible bidi and zero-width characters', () {
      expect(
        AppValidators.normalizeEmail('‏adham@gmail.com‎​ '),
        'adham@gmail.com',
      );
    });

    test('leaves a clean address unchanged', () {
      expect(AppValidators.normalizeEmail('adham@gmail.com'), 'adham@gmail.com');
    });
  });
}
