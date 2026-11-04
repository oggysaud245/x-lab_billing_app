/// Searchable product picker used by the billing screen; adding a product
/// inserts quantity 1 into the working cart.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../shared/app_wiring.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/controllers/billing_state.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/product.dart';
import '../../shared/models/product_category.dart';
import '../../shared/models/unit.dart';
import '../../shared/repositories/product_repository.dart';
import '../../shared/widgets/widgets_extra.dart';

class ProductPickerList extends StatefulWidget {
  final String search;
  final String category;
  final List<ProductCategory> categories;
  final void Function(Product p, Unit unit) onAdd;
  final void Function(Product p)? onRemove;

  const ProductPickerList({
    super.key,
    required this.search,
    this.category = '',
    this.categories = const [],
    required this.onAdd,
    this.onRemove,
  });

  @override
  State<ProductPickerList> createState() => _ProductPickerListState();
}

class _ProductPickerListState extends State<ProductPickerList> {
  List<(Product, Unit)>? _items;
  int _lastDataVersion = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = Provider.of<AppState>(context).dataVersion;
    if (_lastDataVersion != v) {
      _lastDataVersion = v;
      _reload();
    }
  }

  @override
  void didUpdateWidget(covariant ProductPickerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search ||
        oldWidget.category != widget.category) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final products = await AppWiring.products.list(
      ProductQuery(
        search: widget.search,
        category: widget.category,
      ),
    );
    if (!mounted) return;
    setState(() {
      _items = [
        for (final p in products)
          if (p.unit != null) (p, p.unit!),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final billing = context.watch<BillingController>();
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return EmptyView(
        text: (widget.search.isEmpty && widget.category.isEmpty)
            ? l.emptyProducts
            : l.emptyProductsSearch,
        icon: Icons.inventory_2_outlined,
      );
    }
    final nepali = app.settings.appLanguage.isNepali;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 10.0;
        const double minCardWidth = 150.0;
        const double maxCardWidth = 260.0;
        const double horizontalPadding = 12.0;
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);

        // Dynamically compute flex columns and card width from available width
        final columns = ((availableWidth + spacing) / (minCardWidth + spacing))
            .floor()
            .clamp(2, 6);
        final dynamicCardWidth =
            ((availableWidth - (columns - 1) * spacing) / columns)
                .clamp(minCardWidth, maxCardWidth);

        final isLargeDisplay = MediaQuery.sizeOf(context).width >= 600;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            isLargeDisplay ? 120 : 96,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.start,
              children: [
                for (final (p, unit) in items)
                  SizedBox(
                    width: dynamicCardWidth,
                    child: _ProductCard(
                      product: p,
                      unit: unit,
                      categories: widget.categories,
                      isSelected: billing.isProductSelected(p),
                      nepali: nepali,
                      onAdd: () => widget.onAdd(p, unit),
                      onRemove: () {
                        if (widget.onRemove != null) {
                          widget.onRemove!(p);
                        } else {
                          context
                              .read<BillingController>()
                              .removeProductById(p.id);
                        }
                      },
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

class _ProductCard extends StatelessWidget {
  final Product product;
  final Unit unit;
  final List<ProductCategory> categories;
  final bool isSelected;
  final bool nepali;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product,
    required this.unit,
    this.categories = const [],
    required this.isSelected,
    required this.nepali,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final isLargeDisplay = MediaQuery.sizeOf(context).width >= 600;
    final deselectColor = theme.colorScheme.onError;
    final deselectBg = theme.colorScheme.error;

    final catName = product.category.isEmpty
        ? ''
        : categories
            .firstWhere(
              (c) => c.key == product.category || c.matches(product.category),
              orElse: () => ProductCategory(nameEn: product.category, nameNe: ''),
            )
            .displayName(nepali: nepali);

    final compat = <String>[];
    if (product.sku.isNotEmpty) compat.add(product.sku);
    if (catName.isNotEmpty) compat.add(catName);
    compat.add(unit.displayName(nepali: nepali));

    return Card(
      key: ValueKey('product-card-${product.id}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isSelected ? null : onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Title + Deselect Button (when selected)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.isActive
                          ? product.displayName(nepali: nepali)
                          : '${product.displayName(nepali: nepali)} (${l.inactiveMark})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? theme.colorScheme.onSurface : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: l.deselect,
                      child: InkWell(
                        key: ValueKey('deselect-product-${product.id}'),
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            width: isLargeDisplay ? 30 : 22,
                            height: isLargeDisplay ? 30 : 22,
                            decoration: BoxDecoration(
                              color: deselectBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close,
                              size: isLargeDisplay ? 18 : 14,
                              color: deselectColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (compat.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  compat.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              // Bottom: Rate
              Text(
                moneyText(app.settings, product.ratePaisa),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
