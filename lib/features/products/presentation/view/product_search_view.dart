import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../details/presentation/views/details_view.dart';
import '../../../home/presentation/widgets/recent_product_data.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';

class ProductSearchView extends StatelessWidget {
  const ProductSearchView({super.key});

  @override
  Widget build(BuildContext context) {

    return const _ProductSearchBody();
  }
}

class _ProductSearchBody extends StatefulWidget {
  const _ProductSearchBody();

  @override
  State<_ProductSearchBody> createState() => _ProductSearchBodyState();
}

class _ProductSearchBodyState extends State<_ProductSearchBody> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    context.read<ProductsCubit>().loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _runSearch(String value) {
    final products = context.read<ProductsCubit>().state.products;
    context.read<ProductsCubit>().search(value, products);
  }

  void _submit(String value) {
    context.read<ProductsCubit>().commitSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _runSearch,
                        onSubmitted: _submit,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  if (!state.hasSearched) {
                    return _RecentSearches(
                      recentSearches: state.recentSearches,
                      onTap: (query) {
                        _controller.text = query;
                        _runSearch(query);
                      },
                    );
                  }

                  if (state.results.isEmpty) {
                    return Center(
                      child: Text(
                        'No products match "${state.query}"',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                    itemCount: state.results.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final product = state.results[index];
                      return RecentProductTile(
                        data: RecentProductData.fromEntity(product),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<ProductsCubit>(),
                              child: DetailsView(product: product),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.recentSearches, required this.onTap});

  final List<String> recentSearches;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) return const SizedBox.shrink();

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        Text('Recent Searches', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
        SizedBox(height: 12.h),
        ...recentSearches.map(
              (query) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: InkWell(
              onTap: () => onTap(query),
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(.08),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 18.sp, color: Colors.grey.shade600),
                    SizedBox(width: 12.w),
                    Text(query, style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}