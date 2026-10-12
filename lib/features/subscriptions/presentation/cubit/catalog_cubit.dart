import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecase/get_catalog_usecase.dart';
import 'catalog_state.dart';

/// The service picker: the catalog and the search text.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._getCatalogUseCase) : super(const CatalogState());

  final GetCatalogUseCase _getCatalogUseCase;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getCatalogUseCase();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (services) => emit(state.copyWith(services: services, isLoading: false)),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));
}
