import 'package:equatable/equatable.dart';

import '../../domain/enties/product_entity.dart';

class ProductsState extends Equatable {
  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.hasLoadedOnce = false,
    this.query = '',
    this.recentSearches = const [],
    this.results = const [],
    this.hasSearched = false,
  });

  final List<ProductEntity> products;
  final bool isLoading;
  final String? error;
  final bool hasLoadedOnce;
  final String query;
  final List<String> recentSearches;
  final List<ProductEntity> results;
  final bool hasSearched;

  int get total => products.length;

  int get active =>
      products.where((p) => p.status == WarrantyStatus.active).length;

  int get expiring =>
      products.where((p) => p.status == WarrantyStatus.expiring).length;

  int get expired =>
      products.where((p) => p.status == WarrantyStatus.expired).length;

  double get totalPrice =>
      products.fold<double>(0.0, (sum, p) => sum + (p.price ?? 0.0));

  ProductsState copyWith({
    List<ProductEntity>? products,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
    String? query,
    List<String>? recentSearches,
    List<ProductEntity>? results,
    bool? hasSearched,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }

  @override
  List<Object?> get props => [
    products, isLoading, error,
    hasLoadedOnce, query, recentSearches,
    results, hasSearched,
  ];
}