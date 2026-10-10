import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/core/widgets/app_snackbar.dart';
import 'package:sakk/l10n/app_localizations.dart';
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

  // Egypt's consumer protection law gives 14 days to return or exchange, so
  // that's the default; the user can change it or clear it.
  final _returnDaysController = TextEditingController(text: '14');

  bool _controllersSeeded = false;

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
    _returnDaysController.dispose();
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
      returnDays: int.tryParse(_returnDaysController.text.trim()),
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
        final isManual = context.read<ScanCubit>().isManualEntry;
        _seedControllersIfNeeded(scanned);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ReviewHeader(
                  title: isManual ? l10n.addProductManuallyTitle : null,
                  subtitle: isManual ? l10n.addProductManuallySubtitle : null,
                  onBack: () {
                    context.read<ScanCubit>().close();
                    Navigator.of(context).maybePop();
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isManual) ...[
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
                          ],

                          FieldLabel(l10n.productName),
                          CapsuleField(
                            semanticLabel: l10n.productName,
                            controller: _nameController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.productNameRequired
                                : null,
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.brand),
                          CapsuleField(
                            semanticLabel: l10n.brand,
                            controller: _brandController,
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.category),
                          CategorySelector(
                            selected: _selectedCategory,
                            onChanged: (category) =>
                                setState(() => _selectedCategory = category),
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.priceEgp),
                          CapsuleField(
                            semanticLabel: l10n.priceEgp,
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                            borderRadius: BorderRadius.circular(16),
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
                            semanticLabel: l10n.warrantyMonths,
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

                          FieldLabel(l10n.returnWindowDays),
                          CapsuleField(
                            semanticLabel: l10n.returnWindowDays,
                            controller: _returnDaysController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              // Optional: empty means no return window to track.
                              if (v == null || v.trim().isEmpty) return null;
                              final n = int.tryParse(v.trim());
                              return n == null || n < 1 || n > 365 ? l10n.invalidReturnDays : null;
                            },
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.store),
                          CapsuleField(
                            semanticLabel: l10n.store,
                            controller: _storeController,
                          ),
                          SizedBox(height: 20.h),

                          FieldLabel(l10n.notes),
                          CapsuleField(
                            semanticLabel: l10n.notes,
                            controller: _notesController,
                            maxLines: 3,
                            minLines: 3,
                          ),
                          SizedBox(height: 32.h),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: isSaving ? null : _save,
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
