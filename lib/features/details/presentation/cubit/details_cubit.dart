import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/get_it.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/domain/usecase/update_product_usecase.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
part 'details_state.dart';

class DetailsCubit extends Cubit<DetailsState> {
  DetailsCubit({
    UpdateProductUseCase? updateProductUseCase,
    ProductsCubit? productsCubit,
  })  : _updateProductUseCase = updateProductUseCase ?? getIt<UpdateProductUseCase>(),
        _productsCubit = productsCubit ?? getIt<ProductsCubit>(),
        super(const DetailsIdle());

  final UpdateProductUseCase _updateProductUseCase;
  final ProductsCubit _productsCubit;

  Future<void> save({
    required String id,
    required String name,
    String? brand,
    required double price,
    required DateTime purchaseDate,
    required int warrantyMonths,
    String? imageUrl,
    String? receiptUrl,
    String? store,
    String? notes,
    required ProductCategory category,
    required String currency,
  }) async {
    emit(const DetailsSaving());

    final result = await _updateProductUseCase(
      id: id,
      name: name,
      brand: brand,
      price: price,
      purchaseDate: purchaseDate,
      warrantyMonths: warrantyMonths,
      imageUrl: imageUrl,
      receiptUrl: receiptUrl,
      store: store,
      notes: notes,
      category: category,
      currency: currency,
    );

    result.fold(
          (failure) => emit(DetailsFailure(failure.message)),
          (product) {
        _productsCubit.refresh();
        emit(DetailsSuccess(product));
      },
    );
  }
}