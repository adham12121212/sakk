import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../../core/di/get_it.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../../../household/presentation/cubit/household_cubit.dart';
import '../../../installments/presentation/cubit/installments_cubit.dart';
import '../../../installments/presentation/widgets/product_installments_section.dart';
import '../cubit/details_cubit.dart';
import '../widgets/details_header.dart';
import '../widgets/details_tab.dart';
import '../widgets/invoice_tab.dart';
import '../widgets/segmented_tabs.dart';
import '../util/share_card_image.dart';
import '../widgets/calendar_actions.dart';
import '../widgets/product_documents_section.dart';
import '../widgets/warranty_extras_section.dart';
import '../widgets/warranty_banner.dart';
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
    final totalDays = product.warrantyEndDate
        .difference(product.purchaseDate)
        .inDays;
    if (totalDays <= 0) return 0;
    return (product.daysRemaining / totalDays).clamp(0.0, 1.0);
  }

  String get _dateLocale {
    final appLocale = Localizations.localeOf(context);
    return appLocale.languageCode == 'ar' ? 'ar_EG' : appLocale.toLanguageTag();
  }

  /// Label/value pairs shared as text and drawn on the share image. No
  /// receipt link: the photo itself is attached when there is one, and the
  /// link would let anyone who sees the message open the receipt.
  List<(String, String)> get _shareRows {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(_dateLocale);
    final daysToReturn = product.daysToReturn;
    return [
      if (product.store != null) (l10n.store, product.store!),
      if (product.price != null)
        (
          l10n.price,
          '${NumberFormat.decimalPattern(_dateLocale).format(product.price!.round())} $_currencyLabel',
        ),
      (l10n.purchaseDate, date.format(product.purchaseDate)),
      (l10n.warrantyPeriod, '${product.warrantyMonths} ${l10n.months}'),
      (l10n.warrantyEnds, date.format(product.warrantyEndDate)),
      if (daysToReturn != null && daysToReturn >= 0)
        (l10n.returnBy, date.format(product.returnByDate!)),
      if (product.serialNumber != null)
        (l10n.serialNumber, product.serialNumber!),
      if (product.invoiceNumber != null)
        (l10n.invoiceNumber, product.invoiceNumber!),
    ];
  }

  /// Arabic text reads "ج.م" after the amount; a Latin "EGP" next to Arabic
  /// digits gets reordered by right-to-left layout.
  String get _currencyLabel =>
      Localizations.localeOf(context).languageCode == 'ar' &&
          product.currency == 'EGP'
      ? 'ج.م'
      : product.currency;

  /// "Samsung · Electronics"
  String get _shareSubtitle => [
    if (product.brand != null) product.brand!,
    CategoryUi.label(context, product.category),
  ].join(' · ');

  /// "Active · 412 days left" / "Expired"
  String get _shareStatus {
    final l10n = AppLocalizations.of(context)!;
    return product.isExpired
        ? _statusLabel
        : '$_statusLabel · ${l10n.daysLeft(product.daysRemaining)}';
  }

  /// Shares the product as one image: the details card, with the receipt
  /// photo when there is one (downloaded first; the listener continues with
  /// DetailsDownloadReady).
  Future<void> _share() async {
    if (product.receiptUrl != null || product.imageUrl != null) {
      context.read<DetailsCubit>().downloadInvoice(product);
    } else {
      await _shareImageCard(null);
    }
  }

  /// Draws the product card (with the receipt photo when there is one) and
  /// shares that single image.
  Future<void> _shareImageCard(String? photoPath) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final photoBytes = photoPath == null
          ? null
          : await File(photoPath).readAsBytes();
      if (!mounted) return;
      final cardPath = await composeShareCard(
        ShareCardData(
          brandName: l10n.appName,
          title: product.name,
          subtitle: _shareSubtitle,
          statusLabel: _shareStatus,
          statusColor: _statusColor,
          rows: _shareRows,
          receiptLabel: l10n.documentReceipt,
          footer: l10n.appTagline,
          textDirection: Directionality.of(context),
          photoBytes: photoBytes,
          fontFamily: GoogleFonts.cairo().fontFamily,
        ),
      );
      if (!mounted) return;
      await _openShareSheet(
        ShareParams(
          files: [XFile(cardPath, mimeType: 'image/png')],
          subject: product.name,
        ),
      );
    } catch (_) {
      if (mounted) _showSnack(l10n.couldNotShare, isError: true);
    }
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
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
        ),
      );
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
    // Linked plans are kept (the database unlinks them), so say so.
    final linkedPlans = getIt<InstallmentsCubit>().state
        .plansForProduct(product.id)
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProductQuestion),
        content: Text(
          linkedPlans == 0
              ? l10n.deleteProductConfirmBody(product.name)
              : '${l10n.deleteProductConfirmBody(product.name)}\n\n${l10n.deleteProductLinkedPlans(linkedPlans)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final deleted = await context.read<DetailsCubit>().delete(product.id);
    // Re-read the plans so none still points at the deleted product (saving
    // a plan with that link would fail).
    if (deleted && linkedPlans > 0) {
      unawaited(getIt<InstallmentsCubit>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = product.imageUrl ?? product.receiptUrl;
    final isBusy =
        _isSharing ||
        context.watch<DetailsCubit>().state is DetailsActionInProgress;

    return BlocListener<DetailsCubit, DetailsState>(
      listener: (context, state) {
        switch (state) {
          case DetailsDownloadReady(:final filePath):
            _shareImageCard(filePath);
          case DetailsGallerySaved():
            _showSnack(l10n.invoiceSavedToPhotos);
          case DetailsDeleted():
            // The server unlinks the product's plans; reload so they show
            // under their own title.
            final installments = getIt<InstallmentsCubit>();
            if (installments.state.plansForProduct(product.id).isNotEmpty) {
              installments.refresh();
            }
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
                warrantyProgress: _warrantyProgress,
                onBack: () => Navigator.of(context).pop(),
                onShare: isBusy ? () {} : _share,
                onDownload: isBusy
                    ? () {}
                    : () => context.read<DetailsCubit>().downloadImageToGallery(
                        product,
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: WarrantyBanner(
                  product: product,
                  warrantyProgress: _warrantyProgress,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: SegmentedTabs(
                  index: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
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
                          CalendarActions(product: product),
                          ProductDocumentsSection(
                            product: product,
                            canEdit: _isMine,
                          ),
                          WarrantyExtrasSection(
                            product: product,
                            canEdit: _isMine,
                          ),
                          // Plans are private, and only the owner can link one.
                          if (_isMine)
                            ProductInstallmentsSection(product: product),
                        ],
                      )
                    : InvoiceTab(
                        imageUrl: product.receiptUrl ?? product.imageUrl,
                      ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
        // Household members only view each other's products.
        bottomNavigationBar: !_isMine
            ? _AddedByBar(
                name: getIt<HouseholdCubit>().state.nameOf(product.ownerId),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: context.palette.cardShadow.isEmpty
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
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
            Icon(
              AppIcons.household,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name == null
                    ? l10n.addedByHouseholdMember
                    : l10n.addedBy(name!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
