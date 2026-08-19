import 'package:shared_preferences/shared_preferences.dart';

abstract class SearchHistoryService {
  Future<List<String>> getRecentSearches();
  Future<void> addSearch(String query);
  Future<void> clearSearches();
}

class SearchHistoryServiceImpl implements SearchHistoryService {
  static const _key = 'recent_product_searches';
  static const _maxEntries = 10;

  @override
  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  @override
  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.removeWhere((s) => s.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);

    await prefs.setStringList(_key, current.take(_maxEntries).toList());
  }

  @override
  Future<void> clearSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}