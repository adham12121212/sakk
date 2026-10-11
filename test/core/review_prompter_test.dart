import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:sakk/core/service/review_prompter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Review implements InAppReview {
  int requests = 0;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> requestReview() async => requests++;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('asks once, on the third saved product', () async {
    SharedPreferences.setMockInitialValues({});
    final review = _Review();
    final prompter = ReviewPrompter(inAppReview: review);
    await prompter.productSaved();
    await prompter.productSaved();
    expect(review.requests, 0);
    await prompter.productSaved();
    expect(review.requests, 1);
    for (var i = 0; i < 5; i++) {
      await prompter.productSaved();
    }
    expect(review.requests, 1);
  });
}
