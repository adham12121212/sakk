import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
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
  int _tabIndex = 0; // 0 = Details, 1 = Invoice
  bool _isWorking = false; // guards Share/Download from double-taps

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
    switch (product.status) {
      case WarrantyStatus.active:
        return 'Active';
      case WarrantyStatus.expiring:
        return 'Expiring';
      case WarrantyStatus.expired:
        return 'Expired';
    }
  }

  double get _warrantyProgress {
    final totalDays =
        product.warrantyEndDate.difference(product.purchaseDate).inDays;
    if (totalDays <= 0) return 0;
    return (product.daysRemaining / totalDays).clamp(0.0, 1.0);
  }

  String get _shareText {
    final buffer = StringBuffer()
      ..writeln(product.name)
      ..writeln(CategoryUi.label(product.category));
    if (product.brand != null) buffer.writeln('Brand: ${product.brand}');
    if (product.store != null) buffer.writeln('Store: ${product.store}');
    if (product.price != null) {
      buffer.writeln('Price: ${product.currency} ${product.price!.toStringAsFixed(2)}');
    }
    buffer
      ..writeln('Purchased: ${_formatDate(product.purchaseDate)}')
      ..writeln('Warranty: ${product.warrantyMonths} months')
      ..writeln('Expires: ${_formatDate(product.warrantyEndDate)}');
    if (product.receiptUrl != null) {
      buffer.writeln('\nInvoice: ${product.receiptUrl}');
    }
    return buffer.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _share() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await Share.share(_shareText, subject: product.name);
    } catch (e) {
      _showSnack('Couldn\'t open the share sheet: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _downloadInvoice() async {
    final url = product.receiptUrl ?? product.imageUrl;
    if (url == null) {
      _showSnack('No invoice image to download for this product.');
      return;
    }
    if (_isWorking) return;
    setState(() => _isWorking = true);

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${product.name}_invoice.jpg');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Invoice — ${product.name}');
    } catch (e) {
      if (mounted) _showSnack('Download failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ));
  }

  Future<void> _editProduct() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditView(
        product: product,
      )),
    );

  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.name}" will be permanently removed. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<ProductsCubit>().deleteProduct(product.id);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      _showSnack('Couldn\'t delete this product. Please try again.', isError: true);
    }
  }

  void _showMoreActions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _editProduct();
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _share();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Download Invoice'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _downloadInvoice();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl ?? product.receiptUrl;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child:
          _Header(
            product: product,
            imageUrl: imageUrl,
            statusColor: _statusColor,
            statusLabel: _statusLabel,
            warrantyProgress: _warrantyProgress,
            onBack: () => Navigator.of(context).pop(),
            onShare: _share,
            onDownload: _downloadInvoice,
            onMore: _showMoreActions,
          )),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: _WarrantyBanner(product: product, statusColor: _statusColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: _SegmentedTabs(
                index: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
              child: _tabIndex == 0
                  ? _DetailsTab(product: product)
                  : _InvoiceTab(imageUrl: product.receiptUrl ?? product.imageUrl),
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
                    onPressed: _confirmDelete,
                    icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    label: Text('Delete', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 52.h,
                  child: FilledButton.icon(
                    onPressed: _editProduct,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.product,
    required this.imageUrl,
    required this.statusColor,
    required this.statusLabel,
    required this.warrantyProgress,
    required this.onBack,
    required this.onShare,
    required this.onDownload,
    required this.onMore,
  });

  final ProductEntity product;
  final String? imageUrl;
  final Color statusColor;
  final String statusLabel;
  final double warrantyProgress;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackBackground(),
            )
          else
            _fallbackBackground(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.65)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
                      Row(
                        children: [
                          _CircleIconButton(icon: Icons.ios_share_rounded, onTap: onShare),
                          SizedBox(width: 8.w),
                          _CircleIconButton(icon: Icons.download_rounded, onTap: onDownload),
                          SizedBox(width: 8.w),
                          _CircleIconButton(icon: Icons.more_horiz_rounded, onTap: onMore),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              product.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.brand != null)
                              Text(
                                product.brand!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 14.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 56.w,
                        height: 56.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeAlign: 2,
                              value: warrantyProgress,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              valueColor:  AlwaysStoppedAnimation(
                                  AppColors.success,

                              ),
                            ),
                            Text(
                              '${(warrantyProgress * 100).round()}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
        ),
      ),
      child: Center(
        child: Icon(
          CategoryUi.icon(product.category),
          size: 64.sp,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }
}

class _WarrantyBanner extends StatelessWidget {
  const _WarrantyBanner({required this.product, required this.statusColor});

  final ProductEntity product;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final days = product.daysRemaining;
    final label = days > 0 ? '$days days left' : 'Warranty expired';
    final expiresLabel =
        '${product.warrantyEndDate.year}-${product.warrantyEndDate.month.toString().padLeft(2, '0')}-${product.warrantyEndDate.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Expires on: $expiresLabel',
                  style: TextStyle(fontSize: 13.sp, color: statusColor.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          Icon(Icons.shield_outlined, color: statusColor, size: 26.sp),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['Details', 'Invoice'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: selected
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.black : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Store',
            value: product.store ?? '—',
          ),
          _DetailRow(
            icon: Icons.credit_card_outlined,
            label: 'Price',
            value: product.price != null
                ? '${product.currency} ${product.price!.toStringAsFixed(0)}'
                : '—',
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Purchase Date',
            value:
            '${product.purchaseDate.year}-${product.purchaseDate.month.toString().padLeft(2, '0')}-${product.purchaseDate.day.toString().padLeft(2, '0')}',
          ),
          _DetailRow(
            icon: Icons.shield_outlined,
            label: 'Warranty Period',
            value: '${product.warrantyMonths} months',
          ),
          _DetailRow(
            icon: Icons.layers_outlined,
            label: 'Category',
            value: CategoryUi.label(product.category),
            isLast: true,
          ),
          if (product.notes != null && product.notes!.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  product.notes!,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.sp, color: Colors.grey.shade600),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTab extends StatelessWidget {
  const _InvoiceTab({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 48.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 40.sp, color: Colors.grey.shade400),
              SizedBox(height: 8.h),
              Text(
                'No invoice available',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InteractiveViewer(
        child: Image.network(
          imageUrl!,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            height: 240.h,
            color: Colors.grey.shade100,
            child: Center(
              child: Icon(Icons.broken_image_outlined, size: 40.sp, color: Colors.grey.shade400),
            ),
          ),
        ),
      ),
    );
  }
}