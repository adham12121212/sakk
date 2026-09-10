import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../cubit/details_cubit.dart';
import '../widgets/details_header.dart';
import '../widgets/details_tab.dart';
import '../widgets/invoice_tab.dart';
import '../widgets/more_actions_sheet.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/warrenty_banner.dart';
import 'edit_view.dart';

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
  bool _isSharing = false; // share stays local — it's a single synchronous OS call, no cubit state needed

  ProductEntity get product => widget.product;

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

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await Share.share(_shareText, subject: product.name);
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.couldNotOpenShareSheet(e.toString()), isError: true);
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

  void _showMoreActions() {
    MoreActionsSheet.show(
      context,
      onEdit: _editProduct,
      onShare: _share,
      onDownload: () => context.read<DetailsCubit>().downloadInvoice(product),
      onDelete: _confirmDelete,
    );
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
            Share.shareXFiles([XFile(filePath)], text: l10n.invoiceShareText(shareText));
          case DetailsDeleted():
            Navigator.of(context).pop();
          case DetailsActionError(:final error):
            final message = switch (error) {
              'no_invoice_url' => l10n.noInvoiceImageToDownload,
              'delete_failed' => l10n.couldNotDeleteProduct,
              _ => l10n.downloadFailed(error.toString()),
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
                onDownload: isBusy ? () {} : () => context.read<DetailsCubit>().downloadInvoice(product),
                onMore: _showMoreActions,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: WarrantyBanner(product: product, statusColor: _statusColor),
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
                    ? DetailsTab(product: product)
                    : InvoiceTab(imageUrl: product.receiptUrl ?? product.imageUrl),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : _confirmDelete,
                      icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      label: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : _editProduct,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.edit),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}