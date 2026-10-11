import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/error/Failure.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/service/warranty_notification_service.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../products/domain/enties/product_document.dart';
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
    String? serialNumber,
    String? invoiceNumber,
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
      serialNumber: serialNumber,
      invoiceNumber: invoiceNumber,
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


  /// Downloads the invoice photo to a temporary file so the share sheet can
  /// attach it; [shareText] (the product details) goes along with it.
  Future<void> downloadInvoice(ProductEntity product, {required String shareText}) async {
    final url = product.receiptUrl ?? product.imageUrl;
    if (url == null) {
      emit(const DetailsActionError('no_invoice_url'));
      return;
    }
    emit(const DetailsActionInProgress());
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      final tempDir = await getTemporaryDirectory();
      // Product names can contain "/" or quotes, which aren't valid in a path.
      // Letters and digits in any language (e.g. Arabic) are kept.
      final safeName = product.name.replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '_');
      final file = File('${tempDir.path}/${safeName}_invoice.jpg');
      await file.writeAsBytes(response.bodyBytes);
      if (isClosed) return;
      emit(DetailsDownloadReady(file.path, shareText));
    } catch (_) {
      if (isClosed) return;
      emit(const DetailsActionError('share_failed'));
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

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      // Letters and digits in any language (e.g. Arabic) are kept.
      final safeName = product.name.replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '_');
      final tempFile = File('${tempDir.path}/$safeName.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      await Gal.putImage(tempFile.path, album: 'Sakk');

      if (isClosed) return;
      emit(DetailsGallerySaved(tempFile.path));
    } on GalException catch (e, st) {
      // Never log the URL: it's a signed link that opens the receipt.
      getIt<AppLogger>().error('Saving invoice to gallery failed: ${e.type}', error: e, stackTrace: st);
      if (isClosed) return;
      emit(DetailsActionError(e));
    } catch (e, st) {
      getIt<AppLogger>().error('Saving invoice to gallery failed', error: e, stackTrace: st);
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

  Future<bool> addDocument({required String productId, required DocumentKind kind, required String filePath}) =>
      _runExtrasAction(() => _productExtrasUseCase.addDocument(productId: productId, kind: kind, filePath: filePath));

  Future<bool> deleteDocument(ProductDocument document) =>
      _runExtrasAction(() => _productExtrasUseCase.deleteDocument(document));

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