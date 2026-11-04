/// Live billing session: the cart, bill-level discount/tax/other-charges,
/// customer, payment and notes. Numbers live as integer paisa (money),
/// thousandths (quantities) and hundredths (percent rates) end to end.
///
/// The controller reads billing defaults (tax rate, default discount,
/// payment method) from [AppState] and follows them until the user edits the
/// corresponding bill field during the current bill.
library;

import 'package:flutter/foundation.dart';

import '../../core/db/app_database.dart';
import '../../core/formatting/money.dart' as money;
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/unit.dart';
import '../repositories/invoice_repository.dart';
import '../services/invoice_service.dart';
import 'app_state.dart';

/// Bill state shared by the billing screen and the finalize dialogs.
class BillingController extends ChangeNotifier {
  /// App-level dependencies; billing defaults flow from here.
  final AppState app;

  BillingController({required this.app}) {
    app.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    syncFromSettings();
    _notify();
  }

  @override
  void dispose() {
    app.removeListener(_onAppStateChanged);
    super.dispose();
  }

  // --- Cart ---------------------------------------------------------------
  final List<CartLine> _lines = [];

  // --- Bill-level editables -------------------------------------------------
  DiscountType _discountType = DiscountType.none;
  int _discountValue = 0; // percent (x100) or fixed paisa
  bool _taxExplicit = false; // user edited tax for this bill
  bool _taxEnabled = false;
  int _taxRate = 0; // hundredths
  bool _discountExplicit = false; // user edited discount for this bill
  int _otherCharges = 0; // paisa
  String _otherChargesNote = '';
  CustomerInfo _customer = const CustomerInfo();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _paymentExplicit = false;
  int _amountPaid = 0; // paisa
  String _notes = '';

  /// Seed the bill defaults from the (already loaded) app settings.
  void syncFromSettings() {
    final s = app.settings;
    if (!_taxExplicit) {
      _taxEnabled = s.taxEnabled;
      _taxRate = s.taxPercent;
    }
    if (!_discountExplicit) {
      final raw = s.defaultDiscountPercent;
      final scaled = (raw > 0 && raw <= 50) ? raw * 100 : raw;
      _discountValue = scaled;
      _discountType = scaled > 0
          ? DiscountType.percent
          : DiscountType.none;
    }
    if (!_paymentExplicit) {
      _paymentMethod = paymentMethodFromCode(s.defaultPaymentMethod);
    }
    for (var i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      final minQ = s.quantityPrecision == 0 ? 1000 : 1;
      final rounded = money.roundQuantityMilli(l.quantityMilli, s.quantityPrecision);
      final validQ = rounded < minQ ? minQ : rounded;
      if (l.quantityMilli != validQ || l.quantityPrecision != s.quantityPrecision) {
        _lines[i] = l.copyWith(
          quantityMilli: validQ,
          quantityPrecision: s.quantityPrecision,
        );
      }
    }
  }

  List<CartLine> get lines => List.of(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get lineCount => _lines.length;

  DiscountType get discountType => _discountType;
  int get discountValue => _discountValue;
  bool get taxEnabled => _taxEnabled;
  int get taxRate => _taxRate;
  int get otherCharges => _otherCharges;
  String get otherChargesNote => _otherChargesNote;
  CustomerInfo get customer => _customer;
  PaymentMethod get paymentMethod => _paymentMethod;
  int get amountPaid => _amountPaid;
  String get notes => _notes;

  BillTotals get totals => BillTotals.compute(
        _lines,
        discountType: _discountType,
        discountValue: _discountValue,
        taxRate: _taxEnabled ? _taxRate : 0,
        otherCharges: _otherCharges,
        amountPaid: _amountPaid,
        quantityPrecision: app.settings.quantityPrecision,
      );

  void _notify() => notifyListeners();

  // --- Cart operations ------------------------------------------------------
  /// Checks whether a product with [productId] is currently in the cart.
  bool hasProduct(int productId) =>
      productId > 0 && _lines.any((l) => l.productId == productId);

  /// Checks whether [product] is currently in the cart.
  bool isProductSelected(Product product) => hasProduct(product.id);

  /// Adds a product line; quantity defaults to 1.000 (one unit).
  /// Once a product is selected, it cannot be selected twice.
  void addProduct(Product p, {required Unit unit, int quantityMilli = 1000}) {
    if (p.id > 0 && hasProduct(p.id)) return;
    final prec = app.settings.quantityPrecision;
    final minQ = prec == 0 ? 1000 : 1;
    final initialQ = quantityMilli <= 0 ? 1000 : quantityMilli;
    final roundedQ = money.roundQuantityMilli(initialQ, prec);
    _lines.add(CartLine(
      productId: p.id,
      nameEn: p.nameEn,
      nameNe: p.nameNe,
      skuSnapshot: p.sku,
      unitSnapshotEn: unit.displayEn,
      unitSnapshotNe: unit.displayNe,
      quantityMilli: roundedQ < minQ ? minQ : roundedQ,
      ratePaisa: p.ratePaisa,
      position: _lines.length,
      quantityPrecision: prec,
    ));
    _notify();
  }

  /// Replaces the exact quantity of the line at [index].
  void setQuantity(int index, int quantityMilli) {
    if (index < 0 || index >= _lines.length) return;
    final prec = app.settings.quantityPrecision;
    final minQ = prec == 0 ? 1000 : 1;
    final rounded = money.roundQuantityMilli(quantityMilli, prec);
    _replace(index, quantityMilli: rounded < minQ ? minQ : rounded);
  }

  int get defaultQuantityStepMilli {
    final prec = app.settings.quantityPrecision;
    if (prec == 0) return 1000;
    return 1000;
  }

  void incrementQuantity(int index, {int? byMilli}) {
    if (index < 0 || index >= _lines.length) return;
    final step = byMilli ?? defaultQuantityStepMilli;
    _adjust(index, step);
  }

  void decrementQuantity(int index, {int? byMilli}) {
    if (index < 0 || index >= _lines.length) return;
    final step = byMilli ?? defaultQuantityStepMilli;
    _adjust(index, -step);
  }

  void _adjust(int index, int deltaMilli) {
    final prec = app.settings.quantityPrecision;
    final minQ = prec == 0 ? 1000 : 1;
    final raw = _lines[index].quantityMilli + deltaMilli;
    final rounded = money.roundQuantityMilli(raw, prec);
    _replace(index, quantityMilli: rounded < minQ ? minQ : rounded);
  }

  void _replace(int index, {required int quantityMilli}) {
    if (index < 0 || index >= _lines.length) return;
    _lines[index] = _lines[index].copyWith(
      quantityMilli: quantityMilli,
      quantityPrecision: app.settings.quantityPrecision,
    );
    _notify();
  }

  void removeLine(int index) {
    if (index < 0 || index >= _lines.length) return;
    _lines.removeAt(index);
    if (_lines.isEmpty) {
      clear();
    } else {
      _notify();
    }
  }

  /// Clears the working bill and resets all participant editables back to defaults.
  void clear() => reset();

  /// Updates any cart lines referencing [p] so edits made on the Products tab
  /// (name, rate, SKU, unit) are reflected immediately in an active bill.
  void syncProduct(Product p, Unit unit) {
    if (p.id <= 0) return;
    var changed = false;
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.productId == p.id) {
        _lines[i] = CartLine(
          productId: p.id,
          nameEn: p.nameEn,
          nameNe: p.nameNe,
          skuSnapshot: p.sku,
          unitSnapshotEn: unit.displayEn,
          unitSnapshotNe: unit.displayNe,
          quantityMilli: line.quantityMilli,
          ratePaisa: p.ratePaisa,
          position: line.position,
        );
        changed = true;
      }
    }
    if (changed) _notify();
  }

  /// Removes any cart lines referencing a product [productId].
  /// If all products are deselected/removed, the cart is cleared.
  void removeProductById(int productId) {
    final before = _lines.length;
    _lines.removeWhere((l) => l.productId == productId);
    if (_lines.length != before) {
      if (_lines.isEmpty) {
        clear();
      } else {
        _notify();
      }
    }
  }

  // --- Bill-level edits ------------------------------------------------------
  void setDiscount(DiscountType type, int value) {
    _discountExplicit = true;
    _discountType = type;
    _discountValue = type == DiscountType.none ? 0 : value;
    _notify();
  }

  void setTax({required bool enabled, int? rateHundredths}) {
    _taxExplicit = true;
    _taxEnabled = enabled;
    _taxRate = rateHundredths ?? _taxRate;
    _notify();
  }

  void setOtherCharges(int amountPaisa, String note) {
    _otherCharges = amountPaisa < 0 ? 0 : amountPaisa;
    _otherChargesNote = note.trim();
    _notify();
  }

  void setCustomer({
    required String name,
    required String phone,
    required String address,
  }) {
    _customer = CustomerInfo(
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
    );
    _notify();
  }

  void setPaymentMethod(PaymentMethod m) {
    _paymentExplicit = true;
    _paymentMethod = m;
    _notify();
  }

  void setAmountPaid(int paisa) {
    _amountPaid = paisa < 0 ? 0 : paisa;
    _notify();
  }

  void setNotes(String n) {
    _notes = n.trim();
    _notify();
  }

  /// The service used for finalize; created on demand so the controller
  /// stays a plain ChangeNotifier.
  InvoiceService service() => InvoiceService(
        openDb: () => AppDatabase.open,
        invoices: InvoiceRepository(open: () => AppDatabase.open),
      );

  /// Validation before finalize; mirrors [InvoiceService.validate] so screens
  /// can localize the message without calling into the service twice.
  BillValidation validate() => InvoiceService.validate(buildRequest());

  FinalizeRequest buildRequest() => FinalizeRequest(
        lines: List.unmodifiable(_lines),
        discountType: _discountType,
        discountValue: _discountValue,
        taxRate: _taxEnabled ? _taxRate : 0,
        otherCharges: _otherCharges,
        otherChargesNote: _otherChargesNote,
        amountPaid: _amountPaid,
        paymentMethod: _paymentMethod,
        customer: _customer,
        notes: _notes,
        quantityPrecision: app.settings.quantityPrecision,
      );

  /// Finalizes the bill: transactionally reserves the invoice number and
  /// persists the invoice with full snapshots via [InvoiceService].
  /// On success the cart is cleared and participant editables reset to the
  /// settings-derived defaults for the next bill.
  Future<Invoice> finalize({
    required InvoiceService invoiceService,
    InvoiceStatus status = InvoiceStatus.success,
  }) async {
    final v = validate();
    if (v != BillValidation.ok) {
      throw BillValidationError(v);
    }
    final saved = await invoiceService.finalizeBill(
      req: buildRequest(),
      settings: app.settings,
      org: app.organization,
      receipt: app.receipt,
      receiptProfile: app.activeProfile,
      status: status,
    );
    reset();
    await app.refreshAfterFinalize();
    return saved;
  }

  /// Clears the working bill and resets participant defaults for a new one.
  void reset() {
    _lines.clear();
    _discountExplicit = false;
    _taxExplicit = false;
    _paymentExplicit = false;
    _discountValue = 0;
    _discountType = DiscountType.none;
    _taxEnabled = false;
    _taxRate = 0;
    _otherCharges = 0;
    _otherChargesNote = '';
    _customer = const CustomerInfo();
    _paymentMethod = PaymentMethod.cash;
    _amountPaid = 0;
    _notes = '';
    syncFromSettings();
    _notify();
  }
}

/// Thrown when a finalize attempt fails [BillValidation], so screens can
/// pick a matching localized message.
class BillValidationError implements Exception {
  final BillValidation validation;
  const BillValidationError(this.validation);
}
