import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakk/features/products/presentation/cubit/product_state.dart';

import '../../../../core/service/warranty_notification_service.dart';
import '../../../../core/util/shared_preferences.dart';
import '../../domain/enties/product_entity.dart';
import '../../domain/usecase/delete_product_usecase.dart';
import '../../domain/usecase/get_products_usecase.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(
      this._getProductsUseCase,
      this._deleteProductUseCase,
      this._historyService,
      this._warrantyNotificationService,
      ) : super(const ProductsState());

  final GetProductsUseCase _getProductsUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final SearchHistoryService _historyService;
  final WarrantyNotificationService _warrantyNotificationService;


  void _safeEmit(ProductsState newState) {
    if (isClosed) return;
    emit(newState);
  }

  Future<void> loadIfNeeded() {
    if (state.hasLoadedOnce || state.isLoading) return Future.value();
    return refresh();
  }

  Future<void> refresh() async {
    _safeEmit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getProductsUseCase();

    result.fold(
          (failure) => _safeEmit(state.copyWith(isLoading: false, error: failure.message)),
          (products) {
        _safeEmit(state.copyWith(products: products, isLoading: false, hasLoadedOnce: true));
        // Fire-and-forget: don't block the UI on notification bookkeeping.
        unawaited(_warrantyNotificationService.checkAndNotify(products));
      },
    );
  }

  /// Deletes the product and, on success, removes it from local state
  /// immediately (no full refetch needed) and cancels any pending
  /// scheduled reminders for it. Returns true on success, false on
  /// failure (with state.error set) — callers can use this to decide
  /// whether to pop/navigate.
  Future<bool> deleteProduct(String id) async {
    final result = await _deleteProductUseCase(id);

    return result.fold(
          (failure) {
        _safeEmit(state.copyWith(error: failure.message));
        return false;
      },
          (_) {
        final updated = state.products.where((p) => p.id != id).toList();
        _safeEmit(state.copyWith(products: updated, clearError: true));
        unawaited(_warrantyNotificationService.cancelScheduledNotifications(id));
        return true;
      },
    );
  }

  Future<void> loadRecentSearches() async {
    final recent = await _historyService.getRecentSearches();
    _safeEmit(state.copyWith(recentSearches: recent));
  }

  void search(String query, List<ProductEntity> allProducts) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _safeEmit(state.copyWith(query: '', results: [], hasSearched: false));
      return;
    }

    final lower = trimmed.toLowerCase();
    final results = allProducts.where((p) {
      return p.name.toLowerCase().contains(lower) ||
          (p.brand?.toLowerCase().contains(lower) ?? false) ||
          (p.store?.toLowerCase().contains(lower) ?? false);
    }).toList();

    _safeEmit(state.copyWith(query: trimmed, results: results, hasSearched: true));
  }

  Future<void> commitSearch(String query) async {
    if (query.trim().isEmpty) return;
    await _historyService.addSearch(query);
    await loadRecentSearches();
  }

  Future<void> getTotalPrice() async {
    _safeEmit(state.copyWith(isLoading: true));

    final result = await _getProductsUseCase();

    result.fold(
          (failure) => _safeEmit(state.copyWith(isLoading: false, error: failure.message)),
          (products) => _safeEmit(state.copyWith(isLoading: false, products: products)),
    );
  }
}