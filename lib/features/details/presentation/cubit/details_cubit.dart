import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/error/Failure.dart';
import '../../../../core/service/warranty_notification_service.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/domain/enties/warranty_claim.dart';
import '../../../products/domain/usecase/product_extras_usecases.dart';
import '../../../products/domain/usecase/update_product_usecase.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
part 'details_state.dart';

class DetailsCubit extends Cubit<DetailsState> {
  DetailsCubit({
    UpdateProductUseCase? updateProductUseCase,
    ProductsCubit? productsCubit,
    WarrantyNotificationService? warrantyNotificationService,
    ProductExtrasUseCase? productExtrasUseCase,
  })  : _productExtrasUseCase = productExtrasUseCase ?? getIt<ProductExtrasUseCase>(),
        _updateProductUseCase = updateProductUseCase ?? getIt<UpdateProductUseCase>(),
        _productsCubit = productsCubit ?? getIt<ProductsCubit>(),
        _warrantyNotificationService =
            warrantyNotificationService ?? getIt<WarrantyNotificationService>(),
        super(const DetailsIdle());

  final UpdateProductUseCase _updateProductUseCase;
  final ProductsCubit _productsCubit;
  final WarrantyNotificationService _warrantyNotificationService;
  final ProductExtrasUseCase _productExtrasUseCase;

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
    int? returnDays,
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
      returnDays: returnDays,
    );

    result.fold(
          (failure) => emit(DetailsFailure(failure.message)),
          (product) {
        _productsCubit.refresh();
        // The purchase date or warranty length may have changed, so the
        // reminders scheduled when it was added would fire on the wrong day.
        _warrantyNotificationService.scheduleFutureNotifications(product);
        emit(DetailsSuccess(product));
      },
    );
  }


  Future<void> downloadInvoice(ProductEntity product) async {
    final url = product.receiptUrl ?? product.imageUrl;
    if (url == null) {
      emit(const DetailsActionError('no_invoice_url'));
      return;
    }
    emit(const DetailsActionInProgress());
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${product.name}_invoice.jpg');
      await file.writeAsBytes(response.bodyBytes);
      emit(DetailsDownloadReady(file.path, product.name));
    } catch (e) {
      emit(DetailsActionError(e));
    }
  }

  Future<void> downloadImageToGallery(ProductEntity product) async {
    final url = product.receiptUrl ?? product.imageUrl;
    if (url == null) {
      emit(const DetailsActionError('no_invoice_url'));
      return;
    }

    emit(const DetailsActionInProgress());
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          emit(const DetailsActionError('gallery_permission_denied'));
          return;
        }
      }

      print('[DEBUG] fetching url: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      print('[DEBUG] status: ${response.statusCode}');
      print('[DEBUG] content-type: ${response.headers['content-type']}');
      print('[DEBUG] bytes length: ${response.bodyBytes.length}');

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final safeName = product.name.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final tempFile = File('${tempDir.path}/$safeName.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      print('[DEBUG] wrote file: ${tempFile.path}, '
          'exists: ${await tempFile.exists()}, '
          'size: ${await tempFile.length()}');

      await Gal.putImage(tempFile.path, album: 'MyAppInvoices');

      print('[DEBUG] Gal.putImage completed without throwing');

      if (isClosed) return;
      emit(DetailsGallerySaved(tempFile.path));
    } on GalException catch (e) {
      print('[DEBUG] GalException: ${e.type} - ${e.type.message}');
      if (isClosed) return;
      emit(DetailsActionError(e));
    } catch (e) {
      print('[DEBUG] generic exception: $e');
      if (isClosed) return;
      emit(DetailsActionError(e));
    }
  }

  /// Adds an extended/store warranty, then reloads the products so the
  /// details screen, status and reminders pick up the new end date.
  Future<bool> addExtraWarranty({
    required String productId,
    required String provider,
    required DateTime startDate,
    required int months,
  }) =>
      _runExtrasAction(
        () => _productExtrasUseCase.addExtraWarranty(
          productId: productId,
          provider: provider,
          startDate: startDate,
          months: months,
        ),
        rescheduleProductId: productId,
      );

  Future<bool> deleteExtraWarranty(String productId, String warrantyId) => _runExtrasAction(
        () => _productExtrasUseCase.deleteExtraWarranty(warrantyId),
        rescheduleProductId: productId,
      );

  Future<bool> startClaim({required String productId, required String issue}) =>
      _runExtrasAction(() => _productExtrasUseCase.addClaim(productId: productId, issue: issue));

  Future<bool> updateClaimStatus(String claimId, ClaimStatus status) =>
      _runExtrasAction(() => _productExtrasUseCase.updateClaimStatus(claimId, status));

  Future<bool> deleteClaim(String claimId) =>
      _runExtrasAction(() => _productExtrasUseCase.deleteClaim(claimId));

  Future<bool> _runExtrasAction(
    Future<Either<Failure, void>> Function() action, {
    String? rescheduleProductId,
  }) async {
    emit(const DetailsActionInProgress());
    final failure = (await action()).fold((f) => f, (_) => null);
    if (failure != null) {
      if (!isClosed) emit(DetailsActionError(failure));
      return false;
    }

    await _productsCubit.refresh();
    if (rescheduleProductId != null) {
      // The coverage end date may have moved, so move the reminders too.
      final product = _productsCubit.state.products.where((p) => p.id == rescheduleProductId).firstOrNull;
      if (product != null) await _warrantyNotificationService.scheduleFutureNotifications(product);
    }
    if (!isClosed) emit(const DetailsIdle());
    return true;
  }

  Future<bool> delete(String productId) async {
    emit(const DetailsActionInProgress());
    final success = await _productsCubit.deleteProduct(productId);
    emit(success ? const DetailsDeleted() : const DetailsActionError('delete_failed'));
    return success;
  }
}