import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../category/presentation/widgets/category_ui.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../util/installment_format.dart';

/// Bottom sheet to pick which of the user's products a plan is for, with a
/// search box. Pops with the product, or null if dismissed.
class ProductPickerSheet extends StatefulWidget {
  const ProductPickerSheet({super.key, required this.products});

  final List<ProductEntity> products;

  static Future<ProductEntity?> show(
    BuildContext context,
    List<ProductEntity> products,
  ) {
    return showModalBottomSheet<ProductEntity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductPickerSheet(products: products),
    );
  }

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  String _query = '';

  List<ProductEntity> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products
        .where(
          (p) => [
            p.name,
            p.brand,
            p.store,
          ].any((s) => s != null && s.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final matches = _matches;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(l10n.chooseProduct, style: textTheme.titleLarge),
              ),
              if (widget.products.length > 5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(AppIcons.search),
                      hintText: l10n.searchProducts,
                    ),
                  ),
                ),
              if (matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    widget.products.isEmpty
                        ? l10n.noProductsToLink
                        : l10n.noProductsMatch,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    itemBuilder: (context, i) {
                      final p = matches[i];
                      final details = [
                        if (p.store != null) p.store!,
                        if (p.price != null)
                          formatMoney(context, p.price!, p.currency),
                      ].join(' · ');
                      return ListTile(
                        leading: Icon(
                          CategoryUi.icon(p.category),
                          color: colorScheme.primary,
                        ),
                        title: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: details.isEmpty
                            ? null
                            : Text(
                                details,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () => Navigator.of(context).pop(p),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
