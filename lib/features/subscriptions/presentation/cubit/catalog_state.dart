import 'package:equatable/equatable.dart';

import '../../domain/entities/catalog_service.dart';

class CatalogState extends Equatable {
  const CatalogState({
    this.services = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  final List<CatalogService> services;
  final bool isLoading;
  final String? error;
  final String query;

  /// Services whose name contains the query, ignoring case.
  List<CatalogService> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return services;
    return services.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  CatalogState copyWith({
    List<CatalogService>? services,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? query,
  }) {
    return CatalogState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [services, isLoading, error, query];
}
