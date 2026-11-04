/// Bottom sheet showing the working bill: per-line steppers, remove, charges/options,
/// totals and the finalize/clear actions.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/money.dart' as money;
import '../../localization/app_localizations.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/controllers/billing_state.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/invoice.dart';
import '../../shared/widgets/widgets_extra.dart';

class CartSheet extends StatefulWidget {
  const CartSheet({super.key});

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  late final BillingController _billing;
  late DiscountType _dType;
  late bool _taxOn;
  late bool _otherOn;
  late PaymentMethod _pay;

  late final TextEditingController _discountCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _otherCtrl;
  late final TextEditingController _otherNoteCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;

  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _billing = Provider.of<BillingController>(context, listen: false);
    final settings = Provider.of<AppState>(context, listen: false).settings;
    final dev = settings.numeralFormat.isDevanagari;

    _dType = _billing.discountType;
    _taxOn = _billing.taxEnabled;
    _otherOn =
        _billing.otherCharges > 0 || _billing.otherChargesNote.isNotEmpty;
    _pay = _billing.paymentMethod;

    _discountCtrl = TextEditingController(
      text: _dType == DiscountType.none || _billing.discountValue == 0
          ? ''
          : money.formatScaled(
              _billing.discountValue,
              scale: _dType == DiscountType.percent
                  ? money.percentScale
                  : money.paisaPerNPR,
              devanagari: dev,
            ),
    );
    _taxCtrl = TextEditingController(
      text: money.formatScaled(
        _taxOn ? _billing.taxRate : settings.taxPercent,
        scale: money.percentScale,
        devanagari: dev,
      ),
    );
    _otherCtrl = TextEditingController(
      text: _billing.otherCharges == 0
          ? ''
          : moneyTextPlain(settings, _billing.otherCharges),
    );
    _otherNoteCtrl = TextEditingController(text: _billing.otherChargesNote);
    _nameCtrl = TextEditingController(text: _billing.customer.name);
    _phoneCtrl = TextEditingController(text: _billing.customer.phone);
    _addressCtrl = TextEditingController(text: _billing.customer.address);
    _notesCtrl = TextEditingController(text: _billing.notes);

    _discountCtrl.addListener(_syncBilling);
    _taxCtrl.addListener(_syncBilling);
    _otherCtrl.addListener(_syncBilling);
    _otherNoteCtrl.addListener(_syncBilling);
    _nameCtrl.addListener(_syncBilling);
    _phoneCtrl.addListener(_syncBilling);
    _addressCtrl.addListener(_syncBilling);
    _notesCtrl.addListener(_syncBilling);
  }

  void _syncBilling() {
    if (_syncing) return;
    _syncing = true;
    try {
      final discount = _dType == DiscountType.none
          ? 0
          : (_dType == DiscountType.percent
              ? (percentFromInput(_discountCtrl.text) ?? 0)
              : (paisaFromInput(_discountCtrl.text) ?? 0));
      final taxRate = _taxOn ? (percentFromInput(_taxCtrl.text) ?? 0) : 0;
      final other = _otherOn ? (paisaFromInput(_otherCtrl.text) ?? 0) : 0;

      _billing
        ..setDiscount(_dType, discount.clamp(0, 999999999))
        ..setTax(enabled: _taxOn, rateHundredths: taxRate.clamp(0, 10000))
        ..setOtherCharges(
          other.clamp(0, 999999999),
          _otherOn ? _otherNoteCtrl.text : '',
        )
        ..setPaymentMethod(_pay)
        ..setCustomer(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
        )
        ..setNotes(_notesCtrl.text);
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _taxCtrl.dispose();
    _otherCtrl.dispose();
    _otherNoteCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _clearBill() async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l.clearBill,
      message: l.clearBillConfirm,
      positiveLabel: l.clearBill,
    );
    if (!mounted) return;
    if (ok) {
      context.read<BillingController>().clear();
      _syncing = true;
      setState(() {
        _otherOn = false;
        _otherCtrl.clear();
        _otherNoteCtrl.clear();
        _dType = DiscountType.none;
        _discountCtrl.clear();
        _taxOn = false;
        _taxCtrl.clear();
        _pay = PaymentMethod.cash;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _addressCtrl.clear();
        _notesCtrl.clear();
      });
      _syncing = false;
      if (mounted) {
        Navigator.pop(context);
        showAppSnackBar(context, l.billClearedMsg);
      }
    }
  }

  void _onFinalize() {
    final l = AppLocalizations.of(context);
    if (_dType != DiscountType.none && _discountCtrl.text.trim().isNotEmpty) {
      final discount = _dType == DiscountType.percent
          ? (percentFromInput(_discountCtrl.text) ?? -1)
          : (paisaFromInput(_discountCtrl.text) ?? -1);
      if (discount < 0) {
        showAppSnackBar(
          context,
          _dType == DiscountType.percent
              ? l.discountPercentHint
              : l.discountAmountHint,
        );
        return;
      }
      if (_dType == DiscountType.fixed &&
          discount > _billing.totals.subtotalPaisa) {
        showAppSnackBar(context, l.discountExceedsSubtotal);
        return;
      }
    }
    if (_taxOn && _taxCtrl.text.trim().isNotEmpty) {
      final tax = percentFromInput(_taxCtrl.text) ?? -1;
      if (tax < 0) {
        showAppSnackBar(context, l.taxPercentHint);
        return;
      }
    }
    _syncBilling();
    Navigator.pop(context, 'finalize');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final billing = context.watch<BillingController>();
    final theme = Theme.of(context);
    final t = billing.totals;
    final otherNote = billing.otherChargesNote.trim();
    final otherName = otherNote.isEmpty ? l.otherCharges : otherNote;

    final summaryRows = <(String, String, Color?, bool)>[
      (l.subtotal, moneyText(app.settings, t.subtotalPaisa), null, false),
      if (t.discountAmount != 0)
        (
          l.discount,
          moneyText(app.settings, -t.discountAmount),
          Colors.green.shade700,
          false
        ),
      if (t.taxAmount != 0)
        (l.tax, moneyText(app.settings, t.taxAmount), null, false),
      if (t.otherCharges != 0)
        (
          otherName,
          moneyText(app.settings, t.otherCharges),
          null,
          false
        ),
      (l.grandTotal, moneyText(app.settings, t.grandTotal), null, true),
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pinned Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    l.currentBill,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (billing.lineCount > 0) ...[
                    const SizedBox(width: 8),
                    Badge(
                      label: Text('${billing.lineCount}'),
                      child: const Icon(Icons.shopping_cart_outlined, size: 20),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            if (billing.isEmpty)
              Padding(
                padding: const EdgeInsets.all(36),
                child: EmptyView(text: l.emptyCart, icon: Icons.receipt_long),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  children: [
                    // Cart Lines
                    for (int i = 0; i < billing.lineCount; i++) ...[
                      _LineTile(index: i),
                      if (i < billing.lineCount - 1)
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    ],
                    const Divider(height: 20),
                    // Other Charges Card
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.otherCharges,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _otherOn,
                                  onChanged: (v) {
                                    setState(() => _otherOn = v);
                                    if (!v) {
                                      _otherCtrl.clear();
                                      _otherNoteCtrl.clear();
                                    }
                                    _syncBilling();
                                  },
                                ),
                              ],
                            ),
                            if (_otherOn) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: TextField(
                                      controller: _otherNoteCtrl,
                                      decoration: InputDecoration(
                                        labelText: l.otherChargesLabel,
                                        hintText: l.otherCharges,
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: TextField(
                                      controller: _otherCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: l.otherChargesHint,
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Discount & Tax Card
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Discount
                            Row(
                              children: [
                                Icon(
                                  Icons.discount_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.discount,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            EnumSegment<DiscountType>(
                              label: l.addDiscount,
                              values: const [
                                DiscountType.none,
                                DiscountType.percent,
                                DiscountType.fixed,
                              ],
                              labelOf: (t) => switch (t) {
                                DiscountType.none => l.noDiscount,
                                DiscountType.percent => l.discountTypePercent,
                                DiscountType.fixed => l.discountTypeFixed,
                              },
                              selected: _dType,
                              onChanged: (t) {
                                setState(() {
                                  _dType = t;
                                  if (t == DiscountType.none) {
                                    _discountCtrl.clear();
                                  }
                                });
                                _syncBilling();
                              },
                            ),
                            if (_dType != DiscountType.none) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _discountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: _dType == DiscountType.percent
                                      ? l.discountPercentHint
                                      : l.discountAmountHint,
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],
                            const Divider(height: 20),
                            // Tax
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.enableTax,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _taxOn,
                                  onChanged: (v) {
                                    setState(() {
                                      _taxOn = v;
                                      if (!v) _taxCtrl.clear();
                                    });
                                    _syncBilling();
                                  },
                                ),
                              ],
                            ),
                            if (_taxOn) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _taxCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: l.taxPercentHint,
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Payment Method Card
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.paymentMethod,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final button = SegmentedButton<PaymentMethod>(
                                  showSelectedIcon: false,
                                  segments: [
                                    ButtonSegment(
                                      value: PaymentMethod.cash,
                                      icon: const Icon(Icons.payments_outlined,
                                          size: 16),
                                      label: Text(l.paymentMethodCash,
                                          softWrap: false),
                                    ),
                                    ButtonSegment(
                                      value: PaymentMethod.qr,
                                      icon: const Icon(Icons.qr_code_2,
                                          size: 16),
                                      label: Text(l.paymentMethodQr,
                                          softWrap: false),
                                    ),
                                    ButtonSegment(
                                      value: PaymentMethod.bankTransfer,
                                      icon: const Icon(
                                          Icons.account_balance_outlined,
                                          size: 16),
                                      label: Text(l.paymentMethodBankTransfer,
                                          softWrap: false),
                                    ),
                                    ButtonSegment(
                                      value: PaymentMethod.other,
                                      icon: const Icon(Icons.more_horiz,
                                          size: 16),
                                      label: Text(l.paymentMethodOther,
                                          softWrap: false),
                                    ),
                                  ],
                                  selected: {_pay},
                                  onSelectionChanged: (s) {
                                    setState(() => _pay = s.first);
                                    _syncBilling();
                                  },
                                );
                                if (constraints.maxWidth >= 500) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: button,
                                  );
                                }
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: button,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Customer Card (Collapsible: Name, Phone, Address only)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          leading: Icon(
                            Icons.person_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            l.customerInformation,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l.customerName,
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneCtrl,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l.customerPhone,
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _addressCtrl,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: l.customerAddress,
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Notes Card (Collapsible)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          leading: Icon(
                            Icons.note_alt_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            l.notes,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            TextField(
                              controller: _notesCtrl,
                              decoration: InputDecoration(
                                labelText: l.notes,
                                hintText: l.notesHint,
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    // Summary Totals
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          for (final (label, val, color, isTotal)
                              in summaryRows)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: isTotal ? 16 : 14,
                                        fontWeight: isTotal
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    val,
                                    style: TextStyle(
                                      fontSize: isTotal ? 16 : 14,
                                      fontWeight: isTotal
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Pinned Bottom Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: billing.isEmpty ? null : _clearBill,
                      child: Text(l.clearBill),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: billing.isEmpty ? null : _onFinalize,
                      icon: const Icon(Icons.point_of_sale),
                      label: Text(l.finalizeAndPrint),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  final int index;
  const _LineTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final billing = context.watch<BillingController>();
    if (index >= billing.lineCount) return const SizedBox.shrink();
    final line = billing.lines[index];
    final nepali = app.settings.appLanguage.isNepali;
    final theme = Theme.of(context);
    final unitName =
        (nepali ? line.unitSnapshotNe : line.unitSnapshotEn).isNotEmpty
            ? (nepali ? line.unitSnapshotNe : line.unitSnapshotEn)
            : (nepali ? line.unitSnapshotEn : line.unitSnapshotNe);

    final currentMilli = line.quantityMilli;
    const presets = [250, 500, 750, 1000, 1500, 2000, 3000, 5000];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Unit Price, Line Total, and Remove Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.nameEn.isEmpty && line.nameNe.isEmpty
                          ? '·'
                          : (nepali
                              ? (line.nameNe.isEmpty ? line.nameEn : line.nameNe)
                              : (line.nameEn.isEmpty ? line.nameNe : line.nameEn)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (unitName.isNotEmpty) unitName,
                        '${l.unitPrice}: ${moneyText(app.settings, line.ratePaisa)}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                moneyText(app.settings, line.lineTotalPaisa),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: l.removeItem,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  final billing = context.read<BillingController>();
                  billing.removeLine(index);
                  if (billing.isEmpty) {
                    showAppSnackBar(context, l.billClearedMsg);
                  } else {
                    showAppSnackBar(context, l.itemRemovedMsg);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stepper: Large - and + buttons with quantity number in a box
          _QtyStepper(index: index),
          const SizedBox(height: 8),
          // Short code for quantity presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in presets) ...[
                  _PresetChip(
                    label: _presetLabel(p, app.settings, unitName),
                    selected: currentMilli == p,
                    onTap: () {
                      context.read<BillingController>().setQuantity(index, p);
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int index;
  const _QtyStepper({required this.index});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final billing = context.watch<BillingController>();
    if (index >= billing.lineCount) return const SizedBox.shrink();
    final line = billing.lines[index];
    final q = line.quantityMilli;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final nepali = app.settings.appLanguage.isNepali;
    final unitName =
        (nepali ? line.unitSnapshotNe : line.unitSnapshotEn).isNotEmpty
            ? (nepali ? line.unitSnapshotNe : line.unitSnapshotEn)
            : (nepali ? line.unitSnapshotEn : line.unitSnapshotNe);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            minimumSize: const Size(42, 42),
            maximumSize: const Size(42, 42),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.remove, size: 22),
          onPressed: () =>
              context.read<BillingController>().decrementQuantity(index),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () =>
              _editQuantityDialog(context, index, q, app.settings, unitName),
          child: Container(
            constraints: const BoxConstraints(minWidth: 70, minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
                  : cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant,
                width: 1.4,
              ),
            ),
            child: Text(
              qtyText(app.settings, q),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            minimumSize: const Size(42, 42),
            maximumSize: const Size(42, 42),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add, size: 22),
          onPressed: () =>
              context.read<BillingController>().incrementQuantity(index),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = selected
        ? (isDark
            ? cs.primary.withValues(alpha: 0.35)
            : cs.primaryContainer)
        : (isDark
            ? cs.surfaceContainerLow
            : cs.surfaceContainerLowest);

    final borderColor = selected
        ? cs.primary
        : cs.outlineVariant.withValues(alpha: 0.7);

    final textColor = selected
        ? (isDark ? cs.primary : cs.onPrimaryContainer)
        : cs.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.6 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

String _presetLabel(int milli, AppSettings settings, String unitName) {
  String numStr;
  if (milli < 1000) {
    numStr = (milli / 1000).toStringAsFixed(3);
  } else if (milli % 1000 == 0) {
    numStr = (milli ~/ 1000).toString();
  } else if (milli % 100 == 0) {
    numStr = (milli / 1000).toStringAsFixed(1);
  } else {
    numStr = (milli / 1000).toStringAsFixed(2);
  }

  final localizedDigits = settings.numeralFormat.isDevanagari
      ? money.toDevanagariDigits(numStr)
      : numStr;

  final trimmedUnit = unitName.trim();
  return trimmedUnit.isEmpty ? localizedDigits : '$localizedDigits $trimmedUnit';
}

Future<void> _editQuantityDialog(
  BuildContext context,
  int index,
  int currentMilli,
  AppSettings settings,
  String unitName,
) async {
  final l = AppLocalizations.of(context);
  final prec = settings.quantityPrecision;
  const presets = [250, 500, 750, 1000, 1500, 2000, 3000, 5000];
  final initialText = money.formatScaled(
    currentMilli,
    scale: money.qtyScale,
    decimals: prec.clamp(0, 3),
    group: false,
    devanagari: false,
  );
  final controller = TextEditingController(text: initialText)
    ..selection =
        TextSelection(baseOffset: 0, extentOffset: initialText.length);

  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.quantity),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: prec > 0),
            decoration: InputDecoration(
              labelText: l.quantity,
              hintText: prec == 0 ? '1' : '1.${'0' * prec}',
              suffixText: unitName.isEmpty ? null : unitName,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final milli = quantityMilliFromInput(v, precision: prec);
              if (milli != null && milli > 0) {
                Navigator.of(ctx).pop(milli);
              }
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in presets) ...[
                  _PresetChip(
                    label: _presetLabel(p, settings, unitName),
                    selected: currentMilli == p,
                    onTap: () {
                      final text = money.formatScaled(
                        p,
                        scale: money.qtyScale,
                        decimals: prec.clamp(0, 3),
                        group: false,
                        devanagari: false,
                      );
                      controller.text = text;
                      controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: text.length,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final milli =
                quantityMilliFromInput(controller.text, precision: prec);
            if (milli != null && milli > 0) {
              Navigator.of(ctx).pop(milli);
            } else {
              showAppSnackBar(context, l.enterValidQuantity);
            }
          },
          child: Text(l.save),
        ),
      ],
    ),
  );

  if (result != null && context.mounted) {
    context.read<BillingController>().setQuantity(index, result);
  }
}
