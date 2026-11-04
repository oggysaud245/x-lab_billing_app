/// Billing tab: searchable product list, the working bill (cart), bill
/// options (discount / tax / other charges / customer / payment / notes)
/// and the finalize dialog (save and/or print).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../shared/app_wiring.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/controllers/billing_state.dart';
import '../../shared/services/invoice_service.dart' show BillValidation;
import '../../shared/models/app_settings.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/product.dart';
import '../../shared/models/product_category.dart';
import '../../shared/models/unit.dart';
import '../../shared/widgets/widgets_extra.dart';
import '../receipt/preview_screen.dart';
import 'cart_sheet.dart';
import 'product_picker.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  String _search = '';
  String _category = '';
  List<ProductCategory> _categories = const [];
  int _lastDataVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = Provider.of<AppState>(context).dataVersion;
    if (_lastDataVersion != v) {
      _lastDataVersion = v;
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await AppWiring.products.categories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final billing = context.watch<BillingController>();
    final app = context.watch<AppState>();
    final nepali = app.settings.appLanguage.isNepali;
    final isLargeDisplay = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navBilling),
      ),
      floatingActionButton: isLargeDisplay
          ? FloatingActionButton.large(
              key: const ValueKey('billing-cart-fab'),
              heroTag: 'billing-cart',
              tooltip: l.currentBill,
              elevation: billing.isEmpty ? 0 : null,
              backgroundColor: billing.isEmpty
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                  : null,
              foregroundColor: billing.isEmpty
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                  : null,
              onPressed: billing.isEmpty ? null : _openCartSheet,
              child: Badge(
                isLabelVisible: billing.lineCount > 0,
                largeSize: 20,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                label: Text('${billing.lineCount}'),
                child: const Icon(Icons.shopping_cart_outlined, size: 36),
              ),
            )
          : FloatingActionButton(
              key: const ValueKey('billing-cart-fab'),
              heroTag: 'billing-cart',
              tooltip: l.currentBill,
              elevation: billing.isEmpty ? 0 : null,
              backgroundColor: billing.isEmpty
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                  : null,
              foregroundColor: billing.isEmpty
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                  : null,
              onPressed: billing.isEmpty ? null : _openCartSheet,
              child: Badge(
                isLabelVisible: billing.lineCount > 0,
                label: Text('${billing.lineCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.searchProductsHintNameSku,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() => _search = v.trim()),
            ),
          ),
          if (_categories.isNotEmpty) ...[
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
                      child: FilterChip(
                        label: Text(c.displayName(nepali: nepali)),
                        selected: _category == c.key,
                        onSelected: (_) => setState(
                            () => _category = _category == c.key ? '' : c.key),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: ProductPickerList(
              search: _search,
              category: _category,
              categories: _categories,
              onAdd: _addProduct,
              onRemove: _removeProduct,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct(Product p, Unit unit) async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    context.read<BillingController>().addProduct(p, unit: unit);
    showAppSnackBar(
      context,
      '${l.itemAddedMsg} — ${p.displayName(nepali: app.settings.appLanguage.isNepali)}',
    );
  }

  Future<void> _removeProduct(Product p) async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final billing = context.read<BillingController>();
    billing.removeProductById(p.id);
    final nepali = app.settings.appLanguage.isNepali;
    if (billing.isEmpty) {
      showAppSnackBar(context, l.billClearedMsg);
    } else {
      showAppSnackBar(
        context,
        '${l.itemRemovedMsg} — ${p.displayName(nepali: nepali)}',
      );
    }
  }

  Future<void> _openCartSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const CartSheet(),
    );
    if (result == 'finalize' && mounted) {
      _finalizeDialog();
    }
  }

  Future<void> _finalizeDialog() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final billing = context.read<BillingController>();

    final v = billing.validate();
    if (v != BillValidation.ok) {
      showAppSnackBar(
        context,
        switch (v) {
          BillValidation.empty || BillValidation.zeroTotal => l.billEmptyError,
          BillValidation.invalidQuantity => l.enterValidQuantity,
          BillValidation.invalidRate => l.enterValidRate,
          BillValidation.ok => '',
        },
      );
      return;
    }

    final res = await showDialog<_FinalizeResult>(
      context: context,
      builder: (c) => _FinalizeTransactionDialog(
        settings: app.settings,
        totals: billing.totals,
        paymentMethod: billing.paymentMethod,
      ),
    );
    if (res == null || !mounted) return;

    try {
      final invoice = await billing.finalize(
        invoiceService: AppWiring.invoiceService,
        status: res.status,
      );
      if (!mounted) return;
      if (res.shouldPrint) {
        Navigator.of(context).push(
          ReceiptPreviewScreen.route(invoice),
        );
      } else {
        showAppSnackBar(
          context,
          res.status == InvoiceStatus.processing
              ? l.invoiceProcessingMsg
              : (res.status == InvoiceStatus.canceled
                  ? l.invoiceVoidedMsg
                  : l.invoiceSavedMsg),
        );
      }
    } on BillValidationError catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          switch (e.validation) {
            BillValidation.empty || BillValidation.zeroTotal => l.billEmptyError,
            BillValidation.invalidQuantity => l.enterValidQuantity,
            BillValidation.invalidRate => l.enterValidRate,
            BillValidation.ok => '',
          },
        );
      }
    } on Exception catch (e) {
      if (mounted) showAppSnackBar(context, '$e');
    }
  }
}

class _FinalizeResult {
  final bool shouldPrint;
  final InvoiceStatus status;
  const _FinalizeResult({required this.shouldPrint, required this.status});
}

class _FinalizeTransactionDialog extends StatefulWidget {
  final AppSettings settings;
  final BillTotals totals;
  final PaymentMethod paymentMethod;

  const _FinalizeTransactionDialog({
    required this.settings,
    required this.totals,
    required this.paymentMethod,
  });

  @override
  State<_FinalizeTransactionDialog> createState() =>
      _FinalizeTransactionDialogState();
}

class _FinalizeTransactionDialogState
    extends State<_FinalizeTransactionDialog> {
  InvoiceStatus _status = InvoiceStatus.processing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(l.transactionConfirmation)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grand Total Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.grandTotal,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moneyText(widget.settings, widget.totals.grandTotal),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        switch (widget.paymentMethod) {
                          PaymentMethod.cash => Icons.payments_outlined,
                          PaymentMethod.qr => Icons.qr_code_2,
                          PaymentMethod.bankTransfer =>
                            Icons.account_balance_outlined,
                          PaymentMethod.other => Icons.more_horiz,
                        },
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        switch (widget.paymentMethod) {
                          PaymentMethod.cash => l.paymentMethodCash,
                          PaymentMethod.qr => l.paymentMethodQr,
                          PaymentMethod.bankTransfer =>
                            l.paymentMethodBankTransfer,
                          PaymentMethod.other => l.paymentMethodOther,
                        },
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transaction Status Selection
            Text(
              l.transactionStatus,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<InvoiceStatus>(
              segments: [
                ButtonSegment<InvoiceStatus>(
                  value: InvoiceStatus.processing,
                  label: Text(
                    l.statusProcessing,
                    style: const TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.pending_actions_outlined, size: 16),
                ),
                ButtonSegment<InvoiceStatus>(
                  value: InvoiceStatus.success,
                  label: Text(
                    l.statusSuccess,
                    style: const TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                ),
                ButtonSegment<InvoiceStatus>(
                  value: InvoiceStatus.canceled,
                  label: Text(
                    l.statusCanceled,
                    style: const TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            const SizedBox(height: 12),

            // Dynamic Status Hint
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: switch (_status) {
                  InvoiceStatus.processing =>
                    Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
                  InvoiceStatus.success =>
                    Colors.green.withValues(alpha: isDark ? 0.2 : 0.1),
                  InvoiceStatus.canceled => theme.colorScheme.errorContainer
                      .withValues(alpha: isDark ? 0.4 : 0.2),
                },
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: switch (_status) {
                    InvoiceStatus.processing => Colors.amber.shade700,
                    InvoiceStatus.success => Colors.green.shade700,
                    InvoiceStatus.canceled => theme.colorScheme.error,
                  },
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    switch (_status) {
                      InvoiceStatus.processing => Icons.hourglass_top_outlined,
                      InvoiceStatus.success => Icons.check_circle,
                      InvoiceStatus.canceled => Icons.cancel,
                    },
                    size: 18,
                    color: switch (_status) {
                      InvoiceStatus.processing => isDark
                          ? Colors.amber.shade300
                          : Colors.amber.shade900,
                      InvoiceStatus.success => isDark
                          ? Colors.green.shade300
                          : Colors.green.shade900,
                      InvoiceStatus.canceled => theme.colorScheme.error,
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      switch (_status) {
                        InvoiceStatus.processing => l.waitingForPaymentMsg,
                        InvoiceStatus.success => l.paymentConfirmedMsg,
                        InvoiceStatus.canceled => l.transactionCanceledMsg,
                      },
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: switch (_status) {
                          InvoiceStatus.processing => isDark
                              ? Colors.amber.shade300
                              : Colors.amber.shade900,
                          InvoiceStatus.success => isDark
                              ? Colors.green.shade300
                              : Colors.green.shade900,
                          InvoiceStatus.canceled => theme.colorScheme.error,
                        },
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_status == InvoiceStatus.canceled) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(
              context,
              const _FinalizeResult(
                shouldPrint: false,
                status: InvoiceStatus.canceled,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            child: Text(l.statusCanceled),
          ),
        ] else if (_status == InvoiceStatus.processing) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(
              context,
              const _FinalizeResult(
                shouldPrint: false,
                status: InvoiceStatus.processing,
              ),
            ),
            child: Text(l.saveAsProcessing),
          ),
          FilledButton.icon(
            onPressed: null, // Disabled while waiting for paid status!
            icon: const Icon(Icons.point_of_sale),
            label: Text(l.finalizeAndPrint),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const _FinalizeResult(
                shouldPrint: false,
                status: InvoiceStatus.success,
              ),
            ),
            child: Text(l.finalizeAndSave),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              const _FinalizeResult(
                shouldPrint: true,
                status: InvoiceStatus.success,
              ),
            ),
            icon: const Icon(Icons.point_of_sale),
            label: Text(l.finalizeAndPrint),
          ),
        ],
      ],
    );
  }
}
