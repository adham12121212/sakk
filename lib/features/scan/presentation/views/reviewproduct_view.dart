import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/core/widgets/app_snackbar.dart';
import 'package:sakk/l10n/app_localizations.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../details/presentation/widgets/category_selector.dart';
import '../../../products/domain/enties/scanned_receipt.dart';
import '../cubit/scan_cubit.dart';
import '../widgets/capsule_field.dart';
import '../widgets/confidence_banner.dart';
import '../widgets/datex.dart';
import '../widgets/field_label.dart';
import '../widgets/invoice_preview.dart';
import '../widgets/invoice_preview_dialog.dart';
import '../widgets/review_header.dart';
import 'scan_failed_view.dart';
import '../widgets/scan_skeleton_loader.dart';


class ReviewProductView extends StatelessWidget {
  const ReviewProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReviewProductBody();
  }
}

class _ReviewProductBody extends StatefulWidget {
  const _ReviewProductBody();

  @override
  State<_ReviewProductBody> createState() => _ReviewProductBodyState();
}

class _ReviewProductBodyState extends State<_ReviewProductBody> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _storeController = TextEditingController();
  final _notesController = TextEditingController();

  bool _controllersSeeded = false;

  // Defaults to Other until seeded from the AI's guess (or the user picks
  // one manually) — see _seedControllersIfNeeded.
  ProductCategory _selectedCategory = ProductCategory.other;


  void _seedControllersIfNeeded(ScannedReceiptData scanned) {
    if (_controllersSeeded) return;
    _controllersSeeded = true;
    _nameController.text = scanned.productName ?? '';
    _brandController.text = scanned.brand ?? '';
    _priceController.text = scanned.price?.toStringAsFixed(2) ?? '';
    _warrantyController.text = scanned.warrantyMonths?.toString() ?? '';
    _storeController.text = scanned.store ?? '';
    _selectedCategory = scanned.category ?? ProductCategory.other;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _warrantyController.dispose();
    _storeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final cubit = context.read<ScanCubit>();
    final loadedState = cubit.state;
    if (loadedState is! ScanLoaded) return;
    final current = loadedState.scanned.purchaseDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) cubit.updatePurchaseDate(picked);

  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ScanCubit>().save(
      name: _nameController.text.trim(),
      brand: _emptyToNull(_brandController.text),
      price: double.tryParse(_priceController.text.trim()),
      warrantyMonths: int.parse(_warrantyController.text.trim()),
      store: _emptyToNull(_storeController.text),
      notes: _emptyToNull(_notesController.text),
      category: _selectedCategory,
      currency: 'EGP',
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _handleStateChange(BuildContext context, ScanState state) {
    if (state is ScanSaveFailure) {
      AppSnackBar.error(context, state.message);
    } else if (state is ScanSaveSuccess) {
      final cubit = context.read<ScanCubit>();
      AppSnackBar.success(
        context,
        AppLocalizations.of(context)!.productSavedSuccessfully,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      cubit.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listener: _handleStateChange,
      builder: (context, state) {
        if (state is ScanProcessing) {
          return const ScanSkeletonLoader();
        }

        if (state is ScanProcessingFailed) {
          return ScanFailedView(
            message: state.message,
            onBack: () {
              context.read<ScanCubit>().close();
              Navigator.of(context).maybePop();
            },
          );
        }

        if (state is! ScanLoaded) {
          return const ScanSkeletonLoader();
        }

        final scanned = state.scanned;
        final isSaving = state is ScanSaving;
        final l10n = AppLocalizations.of(context)!;
        _seedControllersIfNeeded(scanned);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: SafeArea(
            child: Column(
              children: [
                ReviewHeader(onBack: () {
                  context.read<ScanCubit>().close();
                  Navigator.of(context).maybePop();
                }),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConfidenceBanner(confidence: scanned.confidence),
                          SizedBox(height: 20.h),

                          InvoicePreview(
                            imageUrl: scanned.receiptImageUrl,
                            onTap: () => showInvoicePreviewDialog(
                              context,
                              scanned.receiptImageUrl,
                            ),
                          ),
                          SizedBox(height: 24.h),

                          FieldLabel(l10n.productName),
                          CapsuleField(
                            controller: _nameController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.productNameRequired
                                : null,
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.brand),
                          CapsuleField(controller: _brandController),
                          SizedBox(height: 20.h),

                          const FieldLabel('Category'),
                          CategorySelector(
                            selected: _selectedCategory,
                            onChanged: (category) =>
                                setState(() => _selectedCategory = category),
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.priceEgp),
                          CapsuleField(
                            controller: _priceController,
                            keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return double.tryParse(v.trim()) == null
                                  ? l10n.invalidNumber
                                  : null;
                            },
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.purchaseDate),
                          InkWell(
                            onTap: isSaving ? null : _pickPurchaseDate,
                            borderRadius: BorderRadius.circular(28.r),
                            child: CapsuleShell(
                              child: Text(
                                (scanned.purchaseDate ?? DateTime.now())
                                    .toIsoDate(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.warrantyMonths),
                          CapsuleField(
                            controller: _warrantyController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l10n.warrantyRequired;
                              }
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 0) {
                                return l10n.invalidWarrantyMonths;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.store),
                          CapsuleField(controller: _storeController),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.notes),
                          CapsuleField(
                            controller: _notesController,
                            maxLines: 3,
                            minLines: 3,
                          ),
                          SizedBox(height: 32.h),

                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: FilledButton(
                              onPressed: isSaving
                                  ? null : _save,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28.r),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(l10n.saveProduct),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}