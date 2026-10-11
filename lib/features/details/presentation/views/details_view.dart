import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/error/Failure.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../../core/di/get_it.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../../../household/presentation/cubit/household_cubit.dart';
import '../cubit/details_cubit.dart';
import '../widgets/details_header.dart';
import '../widgets/details_tab.dart';
import '../widgets/invoice_tab.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/product_documents_section.dart';
import '../widgets/warranty_extras_section.dart';
import '../widgets/warrenty_banner.dart';
import 'edit_view.dart';
import '../../../../core/theme/app_icons.dart';

class DetailsView extends StatelessWidget {
  const DetailsView({super.key, required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      buildWhen: (prev, curr) => prev.products != curr.products,
      builder: (context, state) {
        final current = state.products.firstWhere(
              (p) => p.id == product.id,
          orElse: () => product,
        );
        return _ProductDetailsBody(product: current);
      },
    );
  }
}

class _ProductDetailsBody extends StatefulWidget {
  const _ProductDetailsBody({required this.product});

  final ProductEntity product;

  @override
  State<_ProductDetailsBody> createState() => _ProductDetailsBodyState();
}

class _ProductDetailsBodyState extends State<_ProductDetailsBody> {
  int _tabIndex = 0;
  bool _isSharing = false;

  ProductEntity get product => widget.product;

  bool get _isMine => product.isOwnedBy(getIt<GetUserUseCase>()()?.id);

  Color get _statusColor {
    switch (product.status) {
      case WarrantyStatus.active:
        return AppColors.success;
      case WarrantyStatus.expiring:
        return const Color(0xFFF59E0B);
      case WarrantyStatus.expired:
        return AppColors.error;
    }
  }

  String get _statusLabel {
    final l10n = AppLocalizations.of(context)!;
    switch (product.status) {
      case WarrantyStatus.active:
        return l10n.active;
      case WarrantyStatus.expiring:
        return l10n.expiring;
      case WarrantyStatus.expired:
        return l10n.expired;
    }
  }

  double get _warrantyProgress {
    final totalDays = product.warrantyEndDate.difference(product.purchaseDate).inDays;
    if (totalDays <= 0) return 0;
    return (product.daysRemaining / totalDays).clamp(0.0, 1.0);
  }

  String get _shareText {
    final l10n = AppLocalizations.of(context)!;
    final buffer = StringBuffer()
      ..writeln(product.name)
      ..writeln(CategoryUi.label(context, product.category));
    if (product.brand != null) buffer.writeln(l10n.shareBrand(product.brand!));
    if (product.store != null) buffer.writeln(l10n.shareStore(product.store!));
    if (product.price != null) {
      buffer.writeln(l10n.sharePrice(product.currency, product.price!.toStringAsFixed(2)));
    }
    buffer
      ..writeln(l10n.sharePurchased(_formatDate(product.purchaseDate)))
      ..writeln(l10n.shareWarranty(product.warrantyMonths))
      ..writeln(l10n.shareExpires(_formatDate(product.warrantyEndDate)));
    if (product.receiptUrl != null) buffer.writeln(l10n.shareInvoiceUrl(product.receiptUrl!));
    return buffer.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Shares the product details with the invoice photo attached; the cubit
  /// downloads the photo first and the listener opens the share sheet. With no
  /// invoice, shares the details alone.
  Future<void> _share() async {
    if (product.receiptUrl != null || product.imageUrl != null) {
      context.read<DetailsCubit>().downloadInvoice(product, shareText: _shareText);
      return;
    }
    await _openShareSheet(ShareParams(text: _shareText, subject: product.name));
  }

  Future<void> _openShareSheet(ShareParams params) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await SharePlus.instance.share(params);
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.couldNotShare, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? AppColors.error : null));
  }

  Future<void> _editProduct() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DetailsCubit>(),
          child: EditView(product: product),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProductQuestion),
        content: Text(l10n.deleteProductConfirmBody(product.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<DetailsCubit>().delete(product.id);
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = product.imageUrl ?? product.receiptUrl;
    final isBusy = _isSharing || context.watch<DetailsCubit>().state is DetailsActionInProgress;

    return BlocListener<DetailsCubit, DetailsState>(
      listener: (context, state) {
        switch (state) {
          case DetailsDownloadReady(:final filePath, :final shareText):
            _openShareSheet(ShareParams(
              files: [XFile(filePath, mimeType: 'image/jpeg')],
              text: shareText,
              subject: product.name,
            ));
          case DetailsGallerySaved():
            _showSnack(l10n.invoiceSavedToPhotos);
          case DetailsDeleted():
            Navigator.of(context).pop();
          case DetailsActionError(:final error):
            final message = switch (error) {
              'no_invoice_url' => l10n.noInvoiceImageToDownload,
              'delete_failed' => l10n.couldNotDeleteProduct,
              'share_failed' => l10n.couldNotShare,
              Failure(:final message) => userFacingError(l10n, message),
              _ => l10n.couldNotDownloadInvoice,
            };
            _showSnack(message, isError: true);
          default:
            break;
        }
      },
      child: Scaffold(
          body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: DetailsHeader(
                product: product,
                imageUrl: imageUrl,
                statusColor: _statusColor,
                statusLabel: _statusLabel,
                warrantyProgress: _warrantyProgress,
                onBack: () => Navigator.of(context).pop(),
                onShare: isBusy ? () {} : _share,
                onDownload: isBusy ? () {} : () => context.read<DetailsCubit>().downloadImageToGallery(product),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: WarrantyBanner(product: product, warrantyProgress: _warrantyProgress),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: SegmentedTabs(
                    index: _tabIndex, onChanged: (i) => setState(() => _tabIndex = i)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                child: _tabIndex == 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DetailsTab(product: product),
                          ProductDocumentsSection(product: product, canEdit: _isMine),
                          WarrantyExtrasSection(product: product, canEdit: _isMine),
                        ],
                      )
                    : InvoiceTab(imageUrl: product.receiptUrl ?? product.imageUrl),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
        // Household members only view each other's products.
        bottomNavigationBar: !_isMine
            ? _AddedByBar(name: getIt<HouseholdCubit>().state.nameOf(product.ownerId))
            : DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: context.palette.cardShadow.isEmpty
                ? null
                : const [BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, -6))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : _confirmDelete,
                      icon: const Icon(AppIcons.delete),
                      label: Text(l10n.delete),
                      // Soft red: destructive, but quieter than the main action.
                      style: FilledButton.styleFrom(
                        backgroundColor: context.palette.dangerContainer,
                        foregroundColor: context.palette.danger,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : _editProduct,
                      icon: const Icon(AppIcons.edit),
                      label: Text(l10n.edit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of Edit/Delete on a household member's product.
class _AddedByBar extends StatelessWidget {
  const _AddedByBar({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.household, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name == null ? l10n.addedByHouseholdMember : l10n.addedBy(name!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
