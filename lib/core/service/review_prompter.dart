import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a store rating once, after the user has saved a few products
/// (they've seen the app work by then). The store's own popup is used, and
/// Apple/Google limit how often it can actually appear.
class ReviewPrompter {
  ReviewPrompter({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  static const productsBeforeAsking = 3;
  static const _savedKey = 'review_prompt_products_saved';
  static const _askedKey = 'review_prompt_asked';

  /// Call after a product is saved.
  Future<void> productSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_askedKey) ?? false) return;
      final saved = (prefs.getInt(_savedKey) ?? 0) + 1;
      await prefs.setInt(_savedKey, saved);
      if (saved < productsBeforeAsking || !await _inAppReview.isAvailable()) {
        return;
      }
      await prefs.setBool(_askedKey, true);
      await _inAppReview.requestReview();
    } catch (_) {
      // A rating prompt is never worth an error.
    }
  }
}
