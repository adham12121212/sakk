import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/service/warranty_notification_service.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/domain/enties/scanned_receipt.dart';
import '../../../products/domain/usecase/add_product_usecase.dart';
import '../../../products/domain/usecase/scan_receipt_usecase.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
part 'scan_state.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit({
    ScanReceiptUseCase? scanReceiptUseCase,
    AddProductUseCase? addProductUseCase,
    ProductsCubit? productsCubit,
    WarrantyNotificationService? warrantyNotificationService,
  })  : _scanReceiptUseCase = scanReceiptUseCase ?? getIt<ScanReceiptUseCase>(),
        _addProductUseCase = addProductUseCase ?? getIt<AddProductUseCase>(),
        _productsCubit = productsCubit ?? getIt<ProductsCubit>(),
        _warrantyNotificationService =
            warrantyNotificationService ?? getIt<WarrantyNotificationService>(),
        super(const ScanProcessing());

  final ScanReceiptUseCase _scanReceiptUseCase;
  final AddProductUseCase _addProductUseCase;
  final ProductsCubit _productsCubit;
  final WarrantyNotificationService _warrantyNotificationService;

  Future<void> processReceipt(String imagePath) async {
    final result = await _scanReceiptUseCase(imagePath: imagePath);

    result.fold(
          (failure) => emit(ScanProcessingFailed(failure.message)),
          (scanned) => emit(ScanEditing(scanned: scanned)),
    );
  }

  void updatePurchaseDate(DateTime date) {
    final current = state;
    if (current is! ScanLoaded) return;
    emit(ScanEditing(scanned: current.scanned.copyWith(purchaseDate: date)));
  }

  Future<void> save({
    required String name,
    String? brand,
    double? price,
    required int warrantyMonths,
    String? store,
    String? notes,
    required ProductCategory category,
    required String currency,
  }) async {
    final current = state;
    if (current is! ScanLoaded) return;

    final scanned = current.scanned;
    emit(ScanSaving(scanned: scanned));

    final result = await _addProductUseCase(
      name: name,
      brand: brand,
      price: price,
      purchaseDate: scanned.purchaseDate ?? DateTime.now(),
      warrantyMonths: warrantyMonths,
      imageUrl: scanned.receiptImageUrl,
      receiptUrl: scanned.receiptImageUrl,
      store: store,
      notes: notes,
      status: WarrantyStatus.active,
      currency: currency,
      category: category,
    );

    result.fold(
          (failure) => emit(ScanSaveFailure(scanned: scanned, message: failure.message)),
          (product) {
        _productsCubit.refresh();
        _warrantyNotificationService.scheduleFutureNotifications(product);
        emit(ScanSaveSuccess(scanned: scanned));
      },
    );
  }
}