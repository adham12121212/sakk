import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/details/presentation/cubit/details_cubit.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../scan/presentation/widgets/capsule_field.dart';
import '../../../scan/presentation/widgets/datex.dart';
import '../../../scan/presentation/widgets/field_label.dart';
import '../widgets/category_selector.dart';

class EditView extends StatelessWidget {
  const EditView({super.key, required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DetailsCubit>(),
      child: _EditProductBody(product: product),
    );
  }
}

class _EditProductBody extends StatefulWidget {
  const _EditProductBody({required this.product});

  final ProductEntity product;

  @override
  State<_EditProductBody> createState() => _EditProductBodyState();
}

class _EditProductBodyState extends State<_EditProductBody> {
  final _formKey = GlobalKey<FormState>();

  late final _nameController = TextEditingController(text: widget.product.name);
  late final _brandController = TextEditingController(
    text: widget.product.brand ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.product.price?.toStringAsFixed(2) ?? '',
  );
  late final _warrantyController = TextEditingController(
    text: widget.product.warrantyMonths.toString(),
  );
  late final _storeController = TextEditingController(
    text: widget.product.store ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.product.notes ?? '',
  );
  late final _serialController = TextEditingController(text: widget.product.serialNumber ?? '');
  late final _invoiceController = TextEditingController(text: widget.product.invoiceNumber ?? '');
  late final _returnDaysController = TextEditingController(
    text: widget.product.returnDays?.toString() ?? '',
  );

  late ProductCategory _selectedCategory = widget.product.category;
  late DateTime _purchaseDate = widget.product.purchaseDate;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _warrantyController.dispose();
    _storeController.dispose();
    _notesController.dispose();
    _returnDaysController.dispose();
    _serialController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<DetailsCubit>().save(
      id: widget.product.id,
      name: _nameController.text.trim(),
      brand: _emptyToNull(_brandController.text),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      purchaseDate: _purchaseDate,
      warrantyMonths: int.parse(_warrantyController.text.trim()),
      imageUrl: widget.product.imageUrl,
      receiptUrl: widget.product.receiptUrl,
      store: _emptyToNull(_storeController.text),
      notes: _emptyToNull(_notesController.text),
      category: _selectedCategory,
      currency: 'EGP',
      returnDays: int.tryParse(_returnDaysController.text.trim()),
      serialNumber: _emptyToNull(_serialController.text),
      invoiceNumber: _emptyToNull(_invoiceController.text),
    );
  }

  void _handleStateChange(BuildContext context, DetailsState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state is DetailsFailure) {
      AppSnackBar.error(context, state.message);
    } else if (state is DetailsSuccess) {
      AppSnackBar.success(context, l10n.productUpdated);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<DetailsCubit, DetailsState>(
      listener: _handleStateChange,
      builder: (context, state) {
        final isSaving = state is DetailsSaving;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.editProduct, style: TextStyle(fontSize: 20.sp)),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 25.w, 32.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          _purchaseDate.toIsoDate(),
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

                    FieldLabel(l10n.serialNumber),
                    CapsuleField(
                      semanticLabel: l10n.serialNumber,
                      controller: _serialController,
                    ),
                    SizedBox(height: 20.h),

                    FieldLabel(l10n.invoiceNumber),
                    CapsuleField(
                      semanticLabel: l10n.invoiceNumber,
                      controller: _invoiceController,
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
                            : Text(l10n.saveChanges),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
