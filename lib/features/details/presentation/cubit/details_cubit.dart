import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

  Future<bool> delete(String productId) async {
    emit(const DetailsActionInProgress());
    final success = await _productsCubit.deleteProduct(productId);
    emit(success ? const DetailsDeleted() : const DetailsActionError('delete_failed'));
    return success;
  }
}