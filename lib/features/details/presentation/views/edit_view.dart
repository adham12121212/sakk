import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/details/presentation/cubit/details_cubit.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/widgets/app_snackbar.dart';
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

  late final _nameController =
  TextEditingController(text: widget.product.name);
  late final _brandController =
  TextEditingController(text: widget.product.brand ?? '');
  late final _priceController = TextEditingController(
    text: widget.product.price?.toStringAsFixed(2) ?? '',
  );
  late final _warrantyController =
  TextEditingController(text: widget.product.warrantyMonths.toString());
  late final _storeController =
  TextEditingController(text: widget.product.store ?? '');
  late final _notesController =
  TextEditingController(text: widget.product.notes ?? '');

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
      price: double.parse(_priceController.text.trim()),
      purchaseDate: _purchaseDate,
      warrantyMonths: int.parse(_warrantyController.text.trim()),
      imageUrl: widget.product.imageUrl,
      receiptUrl: widget.product.receiptUrl,
      store: _emptyToNull(_storeController.text),
      notes: _emptyToNull(_notesController.text),
      category: _selectedCategory,
      currency: 'EGP'
    );
  }

  void _handleStateChange(BuildContext context, DetailsState state) {
    if (state is DetailsFailure) {
      AppSnackBar.error(context, state.message);
    } else if (state is DetailsSuccess) {
      AppSnackBar.success(context, 'Product updated');
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DetailsCubit, DetailsState>(
      listener: _handleStateChange,
      builder: (context, state) {
        final isSaving = state is DetailsSaving;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: AppBar(
            title: const Text('Edit Product'),
            backgroundColor: const Color(0xFFF8F9FB),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Product Name'),
                    CapsuleField(
                      controller: _nameController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Product name is required'
                          : null,
                    ),
                    SizedBox(height: 20.h),

                    const FieldLabel('Brand'),
                    CapsuleField(controller: _brandController),
                    SizedBox(height: 20.h),

                    const FieldLabel('Category'),
                    CategorySelector(
                      selected: _selectedCategory,
                      onChanged: (category) =>
                          setState(() => _selectedCategory = category),
                    ),
                    SizedBox(height: 20.h),

                    const FieldLabel('Price (EGP)'),
                    CapsuleField(
                      controller: _priceController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return double.tryParse(v.trim()) == null
                            ? 'Enter a valid number'
                            : null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    const FieldLabel('Purchase Date'),
                    InkWell(
                      onTap: isSaving ? null : _pickPurchaseDate,
                      borderRadius: BorderRadius.circular(28.r),
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

                    const FieldLabel('Warranty (months)'),
                    CapsuleField(
                      controller: _warrantyController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Warranty length is required';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) {
                          return 'Enter a valid number of months';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    const FieldLabel('Store'),
                    CapsuleField(controller: _storeController),
                    SizedBox(height: 20.h),

                    const FieldLabel('Notes'),
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
                        onPressed: isSaving ? null : _save,
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
                            : const Text('Save Changes'),
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