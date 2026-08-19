import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which (productId, warranty status) pairs we've already notified
/// the user about, so re-opening the app or refreshing the product list
/// doesn't spam duplicate local pushes / in-app notifications for the same
/// transition. Backed by SharedPreferences — resets on app data clear /
/// reinstall, which is an acceptable trade-off for this feature.
abstract class NotifiedWarrantiesTracker {
  Future<bool> hasNotified(String productId, String status);
  Future<void> markNotified(String productId, String status);
}

class NotifiedWarrantiesTrackerImpl implements NotifiedWarrantiesTracker {
  static const _key = 'notified_warranty_events';

  @override
  Future<bool> hasNotified(String productId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_key) ?? [];
    return seen.contains('$productId:$status');
  }

  @override
  Future<void> markNotified(String productId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_key) ?? [];
    final entry = '$productId:$status';
    if (!seen.contains(entry)) {
      seen.add(entry);
      await prefs.setStringList(_key, seen);
    }
  }
}