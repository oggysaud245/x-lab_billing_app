/// Products tab: searchable list with category filter, inactive toggle and
/// the bilingual product editor sheet (with custom unit creation).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/money.dart' as money;
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

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _search = '';
  String _category = '';
  bool _includeInactive = false;
  ProductSort _sort = ProductSort.nameAsc;
  List<ProductCategory> _categories = const [];
  int _afterEdit = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await AppWiring.products.categories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final nepali = app.settings.appLanguage.isNepali;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navProducts),
        actions: [
          IconButton(
            tooltip: l.addProduct,
            icon: const Icon(Icons.add),
            onPressed: () => _editProduct(null),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action == 'categories') {
                _openManageCategories();
              } else if (action == 'units') {
                _openManageUnits();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(l.manageCategories),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'units',
                child: Row(
                  children: [
                    const Icon(Icons.straighten_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(l.manageUnits),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.searchProductsHintNameSku,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                PopupMenuButton<ProductSort>(
                  tooltip: l.sortBy,
                  icon: Icon(
                    Icons.sort,
                    color: _sort != ProductSort.nameAsc
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onSelected: (sort) => setState(() => _sort = sort),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ProductSort.nameAsc,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: _sort == ProductSort.nameAsc
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.sortByNameAsc)),
                          if (_sort == ProductSort.nameAsc)
                            Icon(Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ProductSort.nameDesc,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: _sort == ProductSort.nameDesc
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.sortByNameDesc)),
                          if (_sort == ProductSort.nameDesc)
                            Icon(Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: ProductSort.newest,
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: _sort == ProductSort.newest
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.sortByDateNewest)),
                          if (_sort == ProductSort.newest)
                            Icon(Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ProductSort.oldest,
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 18,
                            color: _sort == ProductSort.oldest
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.sortByDateOldest)),
                          if (_sort == ProductSort.oldest)
                            Icon(Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: ProductSort.rateAsc,
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 18,
                            color: _sort == ProductSort.rateAsc
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.sortByRateAsc)),
                          if (_sort == ProductSort.rateAsc)
                            Icon(Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ProductSort.rateDesc,
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            size: 18,
                            color: _sort == ProductSort.rateDesc
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.sortByRateDesc)),
                          if (_sort == ProductSort.rateDesc)
                            Icon(Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: l.showInactiveProducts,
                  isSelected: _includeInactive,
                  icon: Icon(_includeInactive
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _includeInactive = !_includeInactive),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(l.allCategories),
                    selected: _category.isEmpty,
                    onSelected: (_) => setState(() => _category = ''),
                  ),
                ),
                for (final c in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onLongPress: () => _manageCategory(c),
                      child: FilterChip(
                        label: Text(c.displayName(nepali: nepali)),
                        selected: _category == c.key,
                        onSelected: (_) =>
                            setState(() => _category = _category == c.key ? '' : c.key),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _ProductList(
            search: _search,
            category: _category,
            categories: _categories,
            includeInactive: _includeInactive,
            sort: _sort,
            afterEdit: _afterEdit,
            onEdit: _editProduct,
          )),
        ],
      ),
    );
  }

  Future<void> _editProduct(Product? product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ProductEditorSheet(product: product),
    );
    if (!mounted) return;
    setState(() => _afterEdit++);
    _loadCategories();
  }

  Future<void> _manageCategory(ProductCategory cat) async {
    final l = AppLocalizations.of(context);
    final nepali = context.read<AppState>().settings.appLanguage.isNepali;
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                cat.displayName(nepali: nepali),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.editCategory),
              onTap: () => Navigator.pop(c, 'edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l.deleteCategory,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final updated = await showEditCategoryDialog(
        context,
        currentCategory: cat,
        existingCategories: _categories,
      );
      if (updated != null && updated != cat) {
        await AppWiring.products.updateCategory(cat, updated);
        if (!mounted) return;
        showAppSnackBar(context, l.categorySavedMsg);
        await _loadCategories();
        if (_category == cat.key) setState(() => _category = updated.key);
      }
    } else if (action == 'delete') {
      final deleted = await promptDeleteCategory(context, cat);
      if (deleted && mounted) {
        await _loadCategories();
        if (_category == cat.key) setState(() => _category = '');
      }
    }
  }

  Future<void> _openManageCategories() async {
    await showManageCategoriesSheet(
      context,
      onChanged: () async {
        await _loadCategories();
        setState(() => _afterEdit++);
      },
    );
    if (!mounted) return;
    await _loadCategories();
    setState(() => _afterEdit++);
  }

  Future<void> _openManageUnits() async {
    await showManageUnitsSheet(
      context,
      onChanged: () {
        setState(() => _afterEdit++);
      },
    );
    if (!mounted) return;
    setState(() => _afterEdit++);
  }
}

class _ProductList extends StatelessWidget {
  final String search;
  final String category;
  final List<ProductCategory> categories;
  final bool includeInactive;
  final ProductSort sort;
  final int afterEdit;
  final void Function(Product) onEdit;

  const _ProductList({
    required this.search,
    required this.category,
    this.categories = const [],
    required this.includeInactive,
    this.sort = ProductSort.nameAsc,
    required this.afterEdit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final nepali = app.settings.appLanguage.isNepali;
    return FutureBuilder<List<Product>>(
      future: AppWiring.products.list(ProductQuery(
        search: search,
        category: category,
        includeInactive: includeInactive,
        sort: sort,
      )),
      key: ValueKey('$search|$category|$includeInactive|$sort|$afterEdit|${app.dataVersion}'),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = List<Product>.from(snap.data ?? const <Product>[]);
        if (sort == ProductSort.nameAsc) {
          items.sort((a, b) => a
              .displayName(nepali: nepali)
              .toLowerCase()
              .compareTo(b.displayName(nepali: nepali).toLowerCase()));
        } else if (sort == ProductSort.nameDesc) {
          items.sort((a, b) => b
              .displayName(nepali: nepali)
              .toLowerCase()
              .compareTo(a.displayName(nepali: nepali).toLowerCase()));
        }
        if (items.isEmpty) {
          return EmptyView(
            text: search.isEmpty ? l.emptyProducts : l.emptyProductsSearch,
            icon: Icons.inventory_2_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final p = items[i];
            final catName = p.category.isEmpty
                ? ''
                : categories
                    .firstWhere(
                      (c) => c.key == p.category || c.matches(p.category),
                      orElse: () =>
                          ProductCategory(nameEn: p.category, nameNe: ''),
                    )
                    .displayName(nepali: nepali);
            final snText = (nepali || app.settings.numeralFormat.isDevanagari)
                ? money.toDevanagariDigits('${i + 1}')
                : '${i + 1}';
            return ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  snText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.displayName(nepali: nepali) +
                              (p.isActive || !includeInactive
                                  ? ''
                                  : ' (${l.inactiveMark})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              subtitle: Text(
                [p.sku, if (catName.isNotEmpty) catName]
                    .where((t) => t.isNotEmpty)
                    .join(' · '),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moneyText(app.settings, p.ratePaisa),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l.editProduct,
                    onPressed: () => onEdit(p),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Editor sheet
// ---------------------------------------------------------------------------

class _ProductEditorSheet extends StatefulWidget {
  final Product? product;
  const _ProductEditorSheet({required this.product});

  @override
  State<_ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<_ProductEditorSheet> {
  late final TextEditingController _nameEn;
  late final TextEditingController _nameNe;
  late final TextEditingController _sku;
  late final TextEditingController _descEn;
  late final TextEditingController _descNe;
  late final TextEditingController _rate;
  String _selectedCategory = '';
  List<ProductCategory> _categories = const [];
  int? _unitId;
  late bool _active;
  List<Unit> _units = const [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _units = p?.unit != null ? [p!.unit!] : const [];
    _nameEn = TextEditingController(text: p?.nameEn ?? '');
    _nameNe = TextEditingController(text: p?.nameNe ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _descEn = TextEditingController(text: p?.descriptionEn ?? '');
    _descNe = TextEditingController(text: p?.descriptionNe ?? '');
    _rate = TextEditingController(
      text: p == null
          ? ''
          : (p.ratePaisa % money.paisaPerNPR == 0
              ? (p.ratePaisa ~/ money.paisaPerNPR).toString()
              : money.formatScaled(p.ratePaisa, scale: money.paisaPerNPR, group: false)),
    );
    _selectedCategory = p?.category.trim() ?? '';
    _unitId = p?.unitId;
    _active = p?.isActive ?? true;
    _nameEn.addListener(_onFormChanged);
    _rate.addListener(_onFormChanged);
    _loadUnits();
    _loadCategories();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSave {
    if (_nameEn.text.trim().isEmpty) return false;
    if (_rate.text.trim().isEmpty) return false;
    final rate = paisaFromInput(_rate.text);
    if (rate == null || rate < 0) return false;
    if (_unitId == null) return false;
    return true;
  }

  Future<void> _loadUnits() async {
    final units = await AppWiring.units.list();
    if (!mounted) return;
    setState(() {
      _units = units;
    });
  }

  Future<void> _loadCategories() async {
    final cats = await AppWiring.products.categories();
    if (!mounted) return;
    final nepali = Provider.of<AppState>(context, listen: false)
        .settings
        .appLanguage
        .isNepali;
    setState(() {
      final map = <String, ProductCategory>{for (final c in cats) c.key: c};
      if (_selectedCategory.isNotEmpty && !map.containsKey(_selectedCategory)) {
        final existingMatch = cats.cast<ProductCategory?>().firstWhere(
              (c) => c!.matches(_selectedCategory),
              orElse: () => null,
            );
        if (existingMatch != null) {
          _selectedCategory = existingMatch.key;
        } else {
          map[_selectedCategory] =
              ProductCategory(nameEn: _selectedCategory, nameNe: '');
        }
      }
      _categories = map.values.toList()
        ..sort((a, b) => a
            .displayName(nepali: nepali)
            .toLowerCase()
            .compareTo(b.displayName(nepali: nepali).toLowerCase()));
    });
  }

  Future<void> _addCategory() async {
    final l = AppLocalizations.of(context);
    final saved = await showAddCategoryDialog(
      context,
      existingCategories: _categories,
    );
    if (saved != null) {
      await AppWiring.products.addCategory(saved);
      if (!mounted) return;
      showAppSnackBar(context, l.categorySavedMsg);
      setState(() {
        _selectedCategory = saved.key;
      });
      await _loadCategories();
    }
  }

  @override
  void dispose() {
    _nameEn.removeListener(_onFormChanged);
    _rate.removeListener(_onFormChanged);
    _nameEn.dispose();
    _nameNe.dispose();
    _sku.dispose();
    _descEn.dispose();
    _descNe.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nepali = context.watch<AppState>().settings.appLanguage.isNepali;
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: SheetHeader(
                title: widget.product == null ? l.addProduct : l.editProduct,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameEn,
              decoration: InputDecoration(
                  labelText: '${l.productNameEn} *', border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameNe,
              decoration: InputDecoration(
                  labelText: l.productNameNe, border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sku,
                    decoration: InputDecoration(
                        labelText: l.sku, border: const OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: '${l.productRate} *',
                        border: const OutlineInputBorder(),
                        isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _unitId,
                    hint: Text(l.selectUnit),
                    decoration: InputDecoration(
                        labelText: '${l.unit} *',
                        border: const OutlineInputBorder(),
                        isDense: true),
                    items: [
                      for (final u in _units)
                        DropdownMenuItem(
                          value: u.id,
                          child: Text(u.nameEn.isEmpty &&
                                  u.nameNe.isEmpty
                              ? '×'
                              : '${u.nameEn.isNotEmpty ? u.nameEn : u.nameNe}'
                                  ' (${u.displayName(nepali: true)})'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _unitId = v),
                  ),
                ),
                IconButton(
                  tooltip: l.addCustomUnit,
                  icon: const Icon(Icons.add),
                  onPressed: _addUnit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: l.category,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l.noCategory),
                      ),
                      for (final c in _categories)
                        DropdownMenuItem(
                          value: c.key,
                          child: Text(c.displayName(nepali: nepali)),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v ?? ''),
                  ),
                ),
                IconButton(
                  tooltip: l.addCategory,
                  icon: const Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descEn,
              decoration: InputDecoration(
                  labelText: l.descriptionEn, border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descNe,
              decoration: InputDecoration(
                  labelText: l.descriptionNe, border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(_active ? l.active : l.inactive),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 16),
            if (widget.product != null) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l.delete),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _canSave ? _save : null,
              child: Text(l.save),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addUnit() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    try {
      final unit = await showAddCustomUnitDialog(context);
      if (unit == null || !mounted) return;
      final existed = _units.any((u) => u.id == unit.id);
      await _loadUnits();
      app.notifyDataChanged();
      if (!mounted) return;
      setState(() => _unitId = unit.id);
      if (existed) {
        showAppSnackBar(context, l.unitExistsMsg);
      } else {
        showAppSnackBar(context, l.productSavedMsg);
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e.message.toString().contains('duplicate') ? l.unitExistsMsg : '$e',
        );
      }
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final billing = context.read<BillingController?>();
    final settings = app.settings;
    if (_nameEn.text.trim().isEmpty) {
      showAppSnackBar(context, l.enterProductNameEn);
      return;
    }
    if (_rate.text.trim().isEmpty) {
      showAppSnackBar(context, l.enterRate);
      return;
    }
    final rate = paisaFromInput(_rate.text);
    if (rate == null || rate < 0) {
      showAppSnackBar(context, l.enterValidRate);
      return;
    }
    if (_unitId == null) {
      showAppSnackBar(context, l.selectUnitRequired);
      return;
    }
    final existing = widget.product;
    final product = Product(
      id: existing?.id ?? 0,
      nameEn: _nameEn.text.trim(),
      nameNe: _nameNe.text.trim(),
      sku: _sku.text.trim(),
      descriptionEn: _descEn.text.trim(),
      descriptionNe: _descNe.text.trim(),
      ratePaisa: rate,
      unitId: _unitId!,
      category: _selectedCategory.trim(),
      isActive: _active,
      createdAt: existing?.createdAt ?? 0,
      updatedAt: existing?.updatedAt ?? 0,
    );
    try {
      if (existing == null) {
        await AppWiring.products.insert(product);
      } else {
        await AppWiring.products.update(product);
        if (billing != null) {
          final unit = _units.where((u) => u.id == product.unitId).firstOrNull;
          if (unit != null) {
            billing.syncProduct(product, unit);
          }
        }
      }
      app.notifyDataChanged();
      if (!mounted) return;
      showAppSnackBar(
        context,
        '${l.productSavedMsg} (${moneyText(settings, rate)})',
      );
      Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) showAppSnackBar(context, '$e');
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final billing = context.read<BillingController?>();
    final p = widget.product;
    if (p == null) return;
    final ok = await showConfirmDialog(
      context,
      title: l.deleteProduct,
      message: l.deleteProductConfirm(p.displayName()),
      positiveLabel: l.delete,
    );
    if (!ok || !mounted) return;
    await AppWiring.products.delete(p.id);
    billing?.removeProductById(p.id);
    app.notifyDataChanged();
    if (!mounted) return;
    showAppSnackBar(context, l.productDeletedMsg);
    Navigator.pop(context);
  }
}

/// Dialog helper to prompt the user for a new category name (English and Nepali).
/// Validates non-empty input and case-insensitive uniqueness against [existingCategories].
Future<ProductCategory?> showAddCategoryDialog(
  BuildContext context, {
  List<ProductCategory> existingCategories = const [],
}) async {
  final l = AppLocalizations.of(context);
  final nameEn = TextEditingController();
  final nameNe = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setDialogState) {
        final canSave =
            nameEn.text.trim().isNotEmpty || nameNe.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(l.addCategory),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameEn,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: l.categoryNameEn,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameNe,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: l.categoryNameNe,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: canSave ? () => Navigator.pop(c, true) : null,
              child: Text(l.save),
            ),
          ],
        );
      },
    ),
  );
  if (saved != true || !context.mounted) return null;
  final en = nameEn.text.trim();
  final ne = nameNe.text.trim();
  if (en.isEmpty && ne.isEmpty) {
    showAppSnackBar(context, l.enterCategoryName);
    return null;
  }
  final exists = existingCategories.any((c) =>
      (en.isNotEmpty && c.nameEn.trim().toLowerCase() == en.toLowerCase()) ||
      (ne.isNotEmpty && c.nameNe.trim().toLowerCase() == ne.toLowerCase()));
  if (exists) {
    showAppSnackBar(context, l.categoryExistsMsg);
    return null;
  }
  return ProductCategory(nameEn: en, nameNe: ne);
}

/// Dialog helper to prompt the user for adding a custom unit.
Future<Unit?> showAddCustomUnitDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final nameEn = TextEditingController();
  final nameNe = TextEditingController();
  final abbrEn = TextEditingController();
  final abbrNe = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setDialogState) {
        final canSave =
            nameEn.text.trim().isNotEmpty || nameNe.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(l.addCustomUnit),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameEn,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                        labelText: l.unitNameEn, isDense: true)),
                const SizedBox(height: 10),
                TextField(
                    controller: nameNe,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                        labelText: l.unitNameNe, isDense: true)),
                const SizedBox(height: 10),
                TextField(
                    controller: abbrEn,
                    decoration: InputDecoration(
                        labelText: l.unitAbbreviationEn, isDense: true)),
                const SizedBox(height: 10),
                TextField(
                    controller: abbrNe,
                    decoration: InputDecoration(
                        labelText: l.unitAbbreviationNe, isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: canSave ? () => Navigator.pop(c, true) : null,
                child: Text(l.save)),
          ],
        );
      },
    ),
  );
  if (saved != true || !context.mounted) return null;
  if (nameEn.text.trim().isEmpty && nameNe.text.trim().isEmpty) {
    showAppSnackBar(context, l.enterUnitName);
    return null;
  }
  return AppWiring.units.addCustom(
    nameEn: nameEn.text.trim(),
    nameNe: nameNe.text.trim(),
    abbrevEn: abbrEn.text.trim(),
    abbrevNe: abbrNe.text.trim(),
  );
}

/// Dialog helper to prompt the user for editing an existing category (English and Nepali).
Future<ProductCategory?> showEditCategoryDialog(
  BuildContext context, {
  required ProductCategory currentCategory,
  List<ProductCategory> existingCategories = const [],
}) async {
  final l = AppLocalizations.of(context);
  final nameEn = TextEditingController(text: currentCategory.nameEn);
  final nameNe = TextEditingController(text: currentCategory.nameNe);
  final saved = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setDialogState) {
        final en = nameEn.text.trim();
        final ne = nameNe.text.trim();
        final hasName = en.isNotEmpty || ne.isNotEmpty;
        final changed = en != currentCategory.nameEn.trim() ||
            ne != currentCategory.nameNe.trim();
        final canSave = hasName && changed;
        return AlertDialog(
          title: Text(l.editCategory),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameEn,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: l.categoryNameEn,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameNe,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: l.categoryNameNe,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: canSave ? () => Navigator.pop(c, true) : null,
              child: Text(l.save),
            ),
          ],
        );
      },
    ),
  );
  if (saved != true || !context.mounted) return null;
  final en = nameEn.text.trim();
  final ne = nameNe.text.trim();
  if (en.isEmpty && ne.isEmpty) return null;
  final exists = existingCategories.any((c) =>
      c != currentCategory &&
      ((en.isNotEmpty && c.nameEn.trim().toLowerCase() == en.toLowerCase()) ||
          (ne.isNotEmpty && c.nameNe.trim().toLowerCase() == ne.toLowerCase())));
  if (exists) {
    showAppSnackBar(context, l.categoryExistsMsg);
    return null;
  }
  return ProductCategory(nameEn: en, nameNe: ne);
}

/// Confirmation helper to delete a category, alerting the user if products exist.
Future<bool> promptDeleteCategory(BuildContext context, dynamic category) async {
  final l = AppLocalizations.of(context);
  final ProductCategory cat = category is ProductCategory
      ? category
      : ProductCategory(nameEn: category.toString().trim(), nameNe: '');
  final count = await AppWiring.products.countProductsInCategory(cat);
  if (!context.mounted) return false;
  final nepali = Provider.of<AppState>(context, listen: false)
      .settings
      .appLanguage
      .isNepali;
  final name = cat.displayName(nepali: nepali);
  final message = count > 0
      ? l.deleteCategoryConfirmProducts(name, count)
      : l.deleteCategoryConfirm(name);
  final ok = await showConfirmDialog(
    context,
    title: l.deleteCategory,
    message: message,
    positiveLabel: l.delete,
  );
  if (!ok || !context.mounted) return false;
  await AppWiring.products.deleteCategory(cat);
  if (context.mounted) {
    showAppSnackBar(context, l.categoryDeletedMsg);
  }
  return true;
}

/// Modal bottom sheet to manage all categories (edit, delete, add).
Future<void> showManageCategoriesSheet(
  BuildContext context, {
  VoidCallback? onChanged,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (c) => _ManageCategoriesSheet(onChanged: onChanged),
  );
}

class _ManageCategoriesSheet extends StatefulWidget {
  final VoidCallback? onChanged;
  const _ManageCategoriesSheet({this.onChanged});

  @override
  State<_ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<_ManageCategoriesSheet> {
  List<ProductCategory> _cats = const [];
  Map<String, int> _counts = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppWiring.products.categories();
    final counts = <String, int>{};
    for (final c in list) {
      counts[c.key] = await AppWiring.products.countProductsInCategory(c);
    }
    if (!mounted) return;
    setState(() {
      _cats = list;
      _counts = counts;
      _loading = false;
    });
  }

  Future<void> _edit(ProductCategory cat) async {
    final updated = await showEditCategoryDialog(
      context,
      currentCategory: cat,
      existingCategories: _cats,
    );
    if (updated != null && updated != cat) {
      await AppWiring.products.updateCategory(cat, updated);
      if (!mounted) return;
      showAppSnackBar(context, AppLocalizations.of(context).categorySavedMsg);
      await _load();
      widget.onChanged?.call();
    }
  }

  Future<void> _delete(ProductCategory cat) async {
    final deleted = await promptDeleteCategory(context, cat);
    if (deleted && mounted) {
      await _load();
      widget.onChanged?.call();
    }
  }

  Future<void> _add() async {
    final added = await showAddCategoryDialog(
      context,
      existingCategories: _cats,
    );
    if (added != null) {
      await AppWiring.products.addCategory(added);
      if (!mounted) return;
      showAppSnackBar(context, AppLocalizations.of(context).categorySavedMsg);
      await _load();
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nepali = context.watch<AppState>().settings.appLanguage.isNepali;
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: l.manageCategories),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_cats.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.noCategory,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _cats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final cat = _cats[i];
                    final count = _counts[cat.key] ?? 0;
                    final otherName = nepali ? cat.nameEn : cat.nameNe;
                    final subtitleParts = [
                      if (otherName.isNotEmpty) otherName,
                      l.productCountLabel(count),
                    ];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.label_outline),
                      title: Text(cat.displayName(nepali: nepali)),
                      subtitle: Text(subtitleParts.join(' · ')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: l.editCategory,
                            onPressed: () => _edit(cat),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            tooltip: l.deleteCategory,
                            onPressed: () => _delete(cat),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text(l.addCategory),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to edit an existing custom unit. Standard units cannot be edited.
Future<Unit?> showEditUnitDialog(
  BuildContext context, {
  required Unit unit,
}) async {
  if (!unit.isCustom) return null;
  final l = AppLocalizations.of(context);
  final nameEn = TextEditingController(text: unit.nameEn);
  final nameNe = TextEditingController(text: unit.nameNe);
  final abbrEn = TextEditingController(text: unit.abbrevEn);
  final abbrNe = TextEditingController(text: unit.abbrevNe);

  final saved = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setDialogState) {
        final canSave =
            nameEn.text.trim().isNotEmpty || nameNe.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(l.editUnit),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameEn,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                        labelText: l.unitNameEn, isDense: true)),
                const SizedBox(height: 10),
                TextField(
                    controller: nameNe,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                        labelText: l.unitNameNe, isDense: true)),
                const SizedBox(height: 10),
                TextField(
                    controller: abbrEn,
                    decoration: InputDecoration(
                        labelText: l.unitAbbreviationEn, isDense: true)),
                const SizedBox(height: 10),
                TextField(
                    controller: abbrNe,
                    decoration: InputDecoration(
                        labelText: l.unitAbbreviationNe, isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: canSave ? () => Navigator.pop(c, true) : null,
                child: Text(l.save)),
          ],
        );
      },
    ),
  );

  if (saved != true) return null;
  final updated = unit.copyWith(
    nameEn: nameEn.text.trim(),
    nameNe: nameNe.text.trim(),
    abbrevEn: abbrEn.text.trim(),
    abbrevNe: abbrNe.text.trim(),
  );
  await AppWiring.units.update(updated);
  return updated;
}

/// Confirmation helper to delete a custom unit after verifying it is not in use.
Future<bool> promptDeleteUnit(BuildContext context, Unit unit) async {
  if (!unit.isCustom) return false;
  final l = AppLocalizations.of(context);
  final count = await AppWiring.units.countProductsUsingUnit(unit.id);
  if (!context.mounted) return false;
  if (count > 0) {
    showAppSnackBar(
      context,
      l.cannotDeleteUnitInUse(unit.displayName(), count),
    );
    return false;
  }
  final ok = await showConfirmDialog(
    context,
    title: l.deleteUnit,
    message: l.deleteUnitConfirm(unit.displayName()),
    positiveLabel: l.delete,
  );
  if (!ok || !context.mounted) return false;
  await AppWiring.units.delete(unit.id);
  if (context.mounted) {
    showAppSnackBar(context, l.unitDeletedMsg);
  }
  return true;
}

/// Modal bottom sheet to manage all units (standard and custom).
Future<void> showManageUnitsSheet(
  BuildContext context, {
  VoidCallback? onChanged,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (c) => _ManageUnitsSheet(onChanged: onChanged),
  );
}

class _ManageUnitsSheet extends StatefulWidget {
  final VoidCallback? onChanged;
  const _ManageUnitsSheet({this.onChanged});

  @override
  State<_ManageUnitsSheet> createState() => _ManageUnitsSheetState();
}

class _ManageUnitsSheetState extends State<_ManageUnitsSheet> {
  List<Unit> _units = const [];
  Map<int, int> _counts = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppWiring.units.list();
    final counts = <int, int>{};
    for (final u in list) {
      counts[u.id] = await AppWiring.units.countProductsUsingUnit(u.id);
    }
    if (!mounted) return;
    setState(() {
      _units = list;
      _counts = counts;
      _loading = false;
    });
  }

  Future<void> _edit(Unit unit) async {
    final updated = await showEditUnitDialog(context, unit: unit);
    if (updated != null && mounted) {
      showAppSnackBar(context, AppLocalizations.of(context).productSavedMsg);
      await _load();
      widget.onChanged?.call();
    }
  }

  Future<void> _delete(Unit unit) async {
    final deleted = await promptDeleteUnit(context, unit);
    if (deleted && mounted) {
      await _load();
      widget.onChanged?.call();
    }
  }

  Future<void> _add() async {
    final unit = await showAddCustomUnitDialog(context);
    if (unit != null && mounted) {
      showAppSnackBar(context, AppLocalizations.of(context).productSavedMsg);
      await _load();
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: l.manageUnits),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _units.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = _units[i];
                    final count = _counts[u.id] ?? 0;
                    final displayName = u.nameEn.isNotEmpty
                        ? (u.nameNe.isNotEmpty
                            ? '${u.nameEn} / ${u.nameNe}'
                            : u.nameEn)
                        : u.nameNe;
                    final abbr = u.abbrevEn.isNotEmpty
                        ? (u.abbrevNe.isNotEmpty
                            ? '${u.abbrevEn} / ${u.abbrevNe}'
                            : u.abbrevEn)
                        : u.abbrevNe;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.straighten),
                      title: Text('$displayName ($abbr)'),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: u.isCustom
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              u.isCustom ? l.customUnitBadge : l.standardUnit,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: u.isCustom
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(l.productCountLabel(count)),
                        ],
                      ),
                      trailing: u.isCustom
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l.editUnit,
                                  onPressed: () => _edit(u),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  tooltip: l.deleteUnit,
                                  onPressed: () => _delete(u),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text(l.addCustomUnit),
            ),
          ],
        ),
      ),
    );
  }
}


