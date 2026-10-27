import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/di/get_it.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../details/presentation/cubit/details_cubit.dart';
import '../../../details/presentation/views/details_view.dart';
import '../widgets/product_list_card.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../../../../core/theme/app_icons.dart';

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.back),
                    tooltip: l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    // Theme field (white with hairline in light mode) plus a
                    // clear button once there's text.
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) => TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _runSearch,
                        onSubmitted: _submit,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.searchProductsHint,
                          prefixIcon: const Icon(AppIcons.search),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).deleteButtonTooltip,
                                  icon: const Icon(AppIcons.close, size: 20),
                                  onPressed: () {
                                    _controller.clear();
                                    _runSearch('');
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                    return AppEmptyView(
                      icon: AppIcons.searchEmpty,
                      title: l10n.noProductsMatchQuery(state.query),
                      fillRemaining: true,
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                    children: [
                      for (final (i, product) in state.results.indexed) ...[
                        if (i > 0) SizedBox(height: 12.h),
                        ProductListCard(
                          product: product,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              // Was only providing ProductsCubit here — DetailsView's
                              // body reads/watches DetailsCubit directly, and unlike
                              // the '/details' GoRoute (which wraps both in a
                              // MultiBlocProvider), this Navigator.push path never
                              // provided one. That's what threw "Could not find the
                              // correct Provider<DetailsCubit>" when opening a
                              // product straight from search results.
                              builder: (_) => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(
                                    value: context.read<ProductsCubit>(),
                                  ),
                                  BlocProvider(
                                    create: (_) => getIt<DetailsCubit>(),
                                  ),
                                ],
                                child: DetailsView(product: product),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          AppLocalizations.of(context)!.recentSearches,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        GroupedCard(
          dividerIndent: 48,
          children: [
            for (final query in recentSearches)
              AppCard(
                onTap: () => onTap(query),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.recentSearch,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      AppIcons.fillSuggestion,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
