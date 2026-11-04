/// Invoice detail: snapshot-driven view of a historical invoice, void
/// action, the audit trail of print attempts, and reprint with a language
/// override for the receipt only.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/dates.dart' as d;
import '../../core/formatting/money.dart' show toDevanagariDigits;
import '../../localization/app_localizations.dart';
import '../../shared/app_wiring.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/controllers/printer_state.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/print_job.dart';
import '../../shared/models/unit.dart' show shortUnit;
import '../../shared/services/print_service.dart';
import '../../shared/widgets/widgets_extra.dart';
import '../receipt/preview_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  static Route<InvoiceDetailScreen> route(Invoice invoice) =>
      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice));

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Invoice _invoice;
  List<PrintJob>? _jobs;
  int? _printCount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _reloadJobs();
  }

  Future<void> _reloadJobs() async {
    final jobs = await AppWiring.invoices.printJobsFor(_invoice.id);
    final count = await AppWiring.invoices.printCount(_invoice.id);
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
      _printCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final printerCtrl = context.watch<PrinterController>();
    final t = _invoice.totals;
    final voided = _invoice.status == InvoiceStatus.voided;
    final nepaliNames = app.settings.appLanguage.isNepali;
    final devanagari = nepaliNames || app.settings.numeralFormat.isDevanagari;
    final itemsCountText = devanagari
        ? toDevanagariDigits('${_invoice.items.length}')
        : '${_invoice.items.length}';
    final printCountText = devanagari
        ? toDevanagariDigits('${_printCount ?? 0}')
        : '${_printCount ?? 0}';
    final org = _orgLine(_invoice, nepaliNames);
    final phone = _phoneLine(_invoice);

    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice.invoiceNumber),
        actions: [
          IconButton(
            tooltip: l.voidInvoice,
            icon: const Icon(Icons.cancel_outlined),
            onPressed:
                voided || _busy ? null : () => _voidInvoice(context, l),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (voided)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.cancel,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l.invoiceVoidedMsg)),
                    ],
                  ),
                ),
              ),
            )
          else if (_invoice.status == InvoiceStatus.processing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade700),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top, color: Colors.amber.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.invoiceProcessingMsg,
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _busy ? null : () => _markAsPaid(context, l),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade900,
                        ),
                        child: Text(l.markAsPaid),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nepaliNames
                          ? 'रसिद विवरण'
                          : 'Invoice details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  _row(l.date, d.formatReceiptDateMillis(
                    _invoice.createdAt,
                    system: _invoice.dateSystem == 'bs'
                        ? d.DateSystem.bs
                        : d.DateSystem.ad,
                    style: _invoice.dateStyle == 'long'
                        ? d.DateStyle.longMonth
                        : d.DateStyle.numeric,
                    withTime: true,
                    nepaliNames: nepaliNames,
                    devanagariNumerals: nepaliNames,
                  )),
                  _row(
                    l.transactionStatus,
                    switch (_invoice.status) {
                      InvoiceStatus.processing => l.statusProcessing,
                      InvoiceStatus.success => l.statusSuccess,
                      InvoiceStatus.canceled => l.statusCanceled,
                    },
                  ),
                  _row(
                    l.receiptProfileLabel,
                    _invoice.profileDisplayTitle(
                      app.profiles,
                      l.defaultProfileName,
                    ),
                  ),
                  if (org.isNotEmpty)
                    _row(l.organization, org),
                  if (phone.isNotEmpty)
                    _row(l.phoneLabel, phone),
                  if (_invoice.customer != null)
                    _row(l.customer, _invoice.customer!.name.isEmpty
                        ? '—'
                        : _invoice.customer!.name),
                  if (_invoice.customer?.phone.isNotEmpty ?? false)
                    _row(l.customerPhone, _invoice.customer!.phone),
                  if (_invoice.customer?.address.isNotEmpty ?? false)
                    _row(l.customerAddress, _invoice.customer!.address),
                  if (_invoice.notes.isNotEmpty)
                    _row(l.notes, _invoice.notes),
                ],
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.items,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '$itemsCountText ${nepaliNames ? 'सामान' : 'items'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(48),
                        1: FlexColumnWidth(1.0),
                        2: FixedColumnWidth(56),
                        3: FixedColumnWidth(74),
                        4: FixedColumnWidth(86),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          children: [
                            _tableHeader(
                              context,
                              l.snLabel,
                              align: TextAlign.center,
                            ),
                            _tableHeader(
                              context,
                              l.particularsLabel,
                              align: TextAlign.start,
                            ),
                            _tableHeader(
                              context,
                              l.qtyLabel,
                              align: TextAlign.end,
                            ),
                            _tableHeader(
                              context,
                              l.rateLabel,
                              align: TextAlign.end,
                            ),
                            _tableHeader(
                              context,
                              l.amountLabel,
                              align: TextAlign.end,
                            ),
                          ],
                        ),
                        for (var i = 0; i < _invoice.items.length; i++)
                          _buildItemRow(
                            context,
                            _invoice.items[i],
                            i,
                            app.settings,
                            nepaliNames,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryRow(
                    context,
                    l.subtotal,
                    moneyText(app.settings, t.subtotalPaisa),
                  ),
                  if (t.discountAmount != 0)
                    _summaryRow(
                      context,
                      l.discount,
                      moneyText(app.settings, -t.discountAmount),
                      valueColor: Colors.green.shade700,
                    ),
                  if (t.taxAmount != 0)
                    _summaryRow(
                      context,
                      l.tax,
                      moneyText(app.settings, t.taxAmount),
                    ),
                  if (t.otherCharges != 0)
                    _summaryRow(
                      context,
                      _invoice.otherChargesNote.trim().isEmpty
                          ? l.otherCharges
                          : _invoice.otherChargesNote.trim(),
                      moneyText(app.settings, t.otherCharges),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.grandTotal,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        Text(
                          moneyText(app.settings, t.grandTotal),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_invoice.paymentLabelFor(l).isNotEmpty)
                    _summaryRow(
                      context,
                      l.paymentMethod,
                      _invoice.paymentLabelFor(l),
                    ),
                  if (t.amountPaid != 0) ...[
                    _summaryRow(
                      context,
                      l.amountPaid,
                      moneyText(app.settings, t.amountPaid),
                    ),
                    if (t.balanceDue != 0)
                      _summaryRow(
                        context,
                        t.balanceDue > 0 ? l.dueLabel : l.changeLabel,
                        moneyText(app.settings, t.balanceDue.abs()),
                        bold: true,
                        valueColor: t.balanceDue > 0
                            ? Theme.of(context).colorScheme.error
                            : Colors.green.shade700,
                      ),
                  ],
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.printAttempts,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    l.printedTimes(printCountText),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 18),
                  jobsSummary(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      ReceiptPreviewScreen.route(_invoice),
                    );
                    _reloadJobs();
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l.previewInvoice),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: printerCtrl.selected == null || _busy
                      ? () => showAppSnackBar(context, l.selectPrinterFirst)
                      : _reprint,
                  icon: const Icon(Icons.print_outlined),
                  label: Text(l.reprintInvoice),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget jobsSummary() {
    final l = AppLocalizations.of(context);
    final jobs = _jobs;
    if (jobs == null) return const SizedBox();
    if (jobs.isEmpty) {
      return Text(l.notPrintedYet,
          style: const TextStyle(fontStyle: FontStyle.italic));
    }
    return Column(
      children: [
        for (final j in jobs)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              j.status == PrintJobStatus.sent
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: j.status == PrintJobStatus.sent
                  ? Colors.green.shade600
                  : Theme.of(context).colorScheme.error,
            ),
            title: Text(
              j.status == PrintJobStatus.sent
                  ? l.printAttemptSent
                  : '${l.printAttemptFailed}${j.errorMessage.isEmpty ? '' : ' · ${j.errorMessage}'}',
            ),
            subtitle:
                Text(d.formatListTime(j.attemptedAt) +
                    (j.connectionType == null ? '' : ' · ${j.connectionType}')),
          ),
      ],
    );
  }

  String _itemName(InvoiceItem item, bool nepali) {
    final primary = nepali ? item.nameSnapshotNe : item.nameSnapshotEn;
    final secondary = nepali ? item.nameSnapshotEn : item.nameSnapshotNe;
    if (primary.isNotEmpty) return primary;
    return secondary;
  }

  String _orgLine(Invoice inv, bool nepali) {
    final org = PrintOrchestrator.decodeStringMap(inv.orgSnapshotJson);
    final a = org[nepali ? 'name_ne' : 'name_en'];
    final b = org[nepali ? 'name_en' : 'name_ne'];
    final s = (a is String && a.isNotEmpty) ? a : (b is String ? b : '');
    return s;
  }

  String _phoneLine(Invoice inv) {
    final org = PrintOrchestrator.decodeStringMap(inv.orgSnapshotJson);
    final p = org['phone'];
    return p is String ? p : '';
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
              ),
            ),
          ],
        ),
      );

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: bold
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      );

  Widget _tableHeader(
    BuildContext context,
    String label, {
    TextAlign align = TextAlign.start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        label,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  TableRow _buildItemRow(
    BuildContext context,
    InvoiceItem item,
    int index,
    AppSettings settings,
    bool nepaliNames,
  ) {
    final theme = Theme.of(context);
    final unit = nepaliNames ? item.unitSnapshotNe : item.unitSnapshotEn;
    final fallbackUnit = nepaliNames ? item.unitSnapshotEn : item.unitSnapshotNe;
    final rawUnit = unit.isNotEmpty ? unit : fallbackUnit;
    final displayUnit = shortUnit(rawUnit, nepali: nepaliNames);

    return TableRow(
      decoration: BoxDecoration(
        color: index.isOdd
            ? theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.4)
            : null,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          child: Text(
            (nepaliNames || settings.numeralFormat.isDevanagari)
                ? toDevanagariDigits('${index + 1}')
                : '${index + 1}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _itemName(item, nepaliNames),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.skuSnapshot.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'SKU: ${item.skuSnapshot}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              displayUnit.isNotEmpty
                  ? '${qtyText(settings, item.quantityMilli)} $displayUnit'
                  : qtyText(settings, item.quantityMilli),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              moneyText(settings, item.ratePaisa, withSymbol: false),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              moneyText(settings, item.lineTotalPaisa, withSymbol: false),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _voidInvoice(BuildContext context, AppLocalizations l) async {
    final app = context.read<AppState>();
    final controllerText = TextEditingController();
    final ok = await showConfirmDialog(
      context,
      title: l.voidInvoice,
      message: l.voidInvoiceConfirm(_invoice.invoiceNumber),
      positiveLabel: l.voidInvoice,
    );
    if (!ok || !mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.voidReasonLabel),
        content: TextField(
          controller: controllerText,
          decoration: InputDecoration(
            hintText: l.voidReasonHint,
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(c, controllerText.text.trim()),
              child: Text(l.confirm)),
        ],
      ),
    );
    if (!mounted) return;
    await AppWiring.invoices.voidInvoice(
      _invoice.id,
      (reason == null || reason.isEmpty) ? 'voided' : reason,
    );
    final refreshed = await AppWiring.invoices.byId(_invoice.id);
    app.notifyDataChanged();
    if (!mounted) return;
    setState(() {
      if (refreshed != null) _invoice = refreshed;
    });
    await _reloadJobs();
    showAppSnackBar(context, l.invoiceVoidedMsg);
  }

  Future<void> _markAsPaid(BuildContext context, AppLocalizations l) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await AppWiring.invoices.updateInvoiceStatus(
        _invoice.id,
        InvoiceStatus.success,
      );
      final refreshed = await AppWiring.invoices.byId(_invoice.id);
      app.notifyDataChanged();
      if (!mounted) return;
      setState(() {
        if (refreshed != null) _invoice = refreshed;
      });
      messenger.showSnackBar(SnackBar(content: Text(l.paymentConfirmedMsg)));
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reprint() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final printerCtrl = context.read<PrinterController>();
    setState(() => _busy = true);
    final sent = await printerCtrl.printInvoice(_invoice);
    setState(() => _busy = false);
    await _reloadJobs();
    app.notifyDataChanged();
    if (!mounted) return;
    showAppSnackBar(
      context,
      sent
          ? l.printSentMsg
          : '${l.printAttemptFailed}${printerCtrl.statusDetail == null ? '' : ' · ${printerCtrl.statusDetail}'}',
    );
    if (sent) {
      app.requestBillingTab();
      nav.popUntil((route) => route.isFirst);
    }
  }
}

extension _PaymentLabel on Invoice {
  String paymentLabelFor(AppLocalizations l) => switch (paymentMethod) {
        PaymentMethod.cash => l.paymentMethodCash,
        PaymentMethod.qr => l.paymentMethodQr,
        PaymentMethod.bankTransfer => l.paymentMethodBankTransfer,
        PaymentMethod.other => l.paymentMethodOther,
      };
}
