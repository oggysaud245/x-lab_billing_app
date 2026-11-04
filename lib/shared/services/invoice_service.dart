/// High-level invoice workflow: validation, numbering, finalization with
/// full snapshots, and safe reprint support.
library;

import 'dart:convert';

import 'package:sqflite/sqflite.dart' show Database;

import '../../core/errors/app_exception.dart';
import '../../core/formatting/dates.dart';
import '../../core/formatting/money.dart' as money;
import '../models/app_settings.dart';
import '../models/invoice.dart';
import '../models/organization.dart';
import '../models/receipt_profile.dart';
import '../models/receipt_settings.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/organization_repository.dart';

/// Composed fully at finalization; never re-derived later.
class FinalizeRequest {
  final List<CartLine> lines;
  final DiscountType discountType;
  final int discountValue;
  final int taxRate;
  final int otherCharges;
  final String otherChargesNote;
  final int amountPaid;
  final PaymentMethod paymentMethod;
  final CustomerInfo customer;
  final String notes;
  final int? quantityPrecision;

  const FinalizeRequest({
    required this.lines,
    required this.discountType,
    required this.discountValue,
    required this.taxRate,
    required this.otherCharges,
    required this.otherChargesNote,
    required this.amountPaid,
    required this.paymentMethod,
    required this.customer,
    required this.notes,
    this.quantityPrecision,
  });

  BillTotals totals({int? quantityPrecision}) => BillTotals.compute(
        lines,
        discountType: discountType,
        discountValue: discountValue,
        taxRate: taxRate,
        otherCharges: otherCharges,
        amountPaid: amountPaid,
        quantityPrecision: quantityPrecision ?? this.quantityPrecision,
      );
}

enum BillValidation { ok, empty, zeroTotal, invalidQuantity, invalidRate }

class InvoiceService {
  final Future<Database> Function() openDb;
  final InvoiceRepository invoices;
  const InvoiceService({
    required this.openDb,
    required this.invoices,
  });

  /// Formats an invoice number from the current settings + sequence.
  static String numberFor(AppSettings s, int seq, DateTime now) {
    final digits = s.invoiceDigits.clamp(1, 12);
    final padded = seq.toString().padLeft(digits, '0');
    var prefix = s.invoicePrefix;
    if (s.fiscalYearPrefix) {
      final fy = fiscalYearPrefixFor(now) ?? '';
      if (fy.isNotEmpty) prefix = '$prefix$fy-';
    }
    return '$prefix$padded';
  }

  /// Validates a bill before finalization. Pure function.
  static BillValidation validate(FinalizeRequest req) {
    if (req.lines.isEmpty) return BillValidation.empty;
    for (final l in req.lines) {
      if (l.quantityMilli <= 0) return BillValidation.invalidQuantity;
      if (l.ratePaisa < 0) return BillValidation.invalidRate;
    }
    final t = req.totals();
    if (t.grandTotal > 0 &&
        t.subtotalPaisa - t.discountAmount <= 0 &&
        t.taxAmount == 0 &&
        t.otherCharges == 0) {
      return BillValidation.zeroTotal;
    }
    return BillValidation.ok;
  }

  /// Finalizes: transactionally reserves the number, persists the invoice
  /// and its snapshots, and returns the saved invoice.
  Future<Invoice> finalizeBill({
    required FinalizeRequest req,
    required AppSettings settings,
    required Organization org,
    required ReceiptSettings receipt,
    ReceiptProfile? receiptProfile,
    InvoiceStatus status = InvoiceStatus.success,
  }) async {
    final prec = settings.quantityPrecision;
    final v = validate(req);
    if (v != BillValidation.ok) {
      throw AppException(ErrorCode.invalidInput, 'validation ${v.name}');
    }
    final totals = req.totals(quantityPrecision: prec);
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await openDb();
    final orgSnapshot = await OrganizationRepository.fromDb(db);
    final invLang = _resolveInvoiceLanguage(settings);
    var receiptJson = receipt.encodeSnapshot();
    if (receiptProfile != null) {
      try {
        final decoded = jsonDecode(receiptJson) as Map<String, Object?>;
        decoded['profile_id'] = receiptProfile.id;
        decoded['profile_name'] = receiptProfile.displayTitle('');
        receiptJson = jsonEncode(decoded);
      } catch (_) {}
    }
    final draft = Invoice(
      id: 0,
      invoiceNumber: '', // assigned inside the transaction
      invoiceNumberSeq: 0,
      createdAt: now,
      orgSnapshotJson: orgSnapshot.encodeSnapshot(),
      receiptSnapshotJson: receiptJson,
      appSettingsSnapshotJson:
          settingsSnapshotJson(settings, receiptProfile: receiptProfile),
      invoiceLanguage: invLang,
      dateSystem: settings.useBikramSambat ? 'bs' : 'ad',
      dateStyle: settings.longDateStyle ? 'long' : 'numeric',
      numeralFormat: invLang.nepali ? 'devanagari' : 'western',
      customer: req.customer.isEmpty ? null : req.customer,
      items: [
        for (var i = 0; i < req.lines.length; i++)
          InvoiceItem(
            id: 0,
            productId: req.lines[i].productId,
            nameSnapshotEn: req.lines[i].nameEn,
            nameSnapshotNe: req.lines[i].nameNe,
            skuSnapshot: req.lines[i].skuSnapshot,
            unitSnapshotEn: req.lines[i].unitSnapshotEn,
            unitSnapshotNe: req.lines[i].unitSnapshotNe,
            quantityMilli:
                money.roundQuantityMilli(req.lines[i].quantityMilli, prec),
            ratePaisa: req.lines[i].ratePaisa,
            lineTotalPaisa: money.lineTotalPaisa(
              req.lines[i].quantityMilli,
              req.lines[i].ratePaisa,
              precision: prec,
            ),
            position: i,
          ),
      ],
      totals: totals,
      paymentMethod: req.paymentMethod,
      otherChargesNote: req.otherChargesNote,
      notes: req.notes,
      status: status,
      statusNote: '',
      printCount: 0,
    );

    final saved = await invoices.finalize(
      draft,
      buildNumber: (seq) => numberFor(settings, seq, DateTime.now()),
    );
    return saved;
  }

  static InvoiceLanguage _resolveInvoiceLanguage(AppSettings s) {
    switch (s.invoiceLanguageMode) {
      case InvoiceLanguageMode.en:
        return InvoiceLanguage.en;
      case InvoiceLanguageMode.ne:
        return InvoiceLanguage.ne;
      case InvoiceLanguageMode.followApp:
        return s.appLanguage.isNepali ? InvoiceLanguage.ne : InvoiceLanguage.en;
    }
  }
}

/// JSON of the numeric/format settings preserved with each finalized
/// invoice so historical reprints keep their original look.
String settingsSnapshotJson(AppSettings s, {ReceiptProfile? receiptProfile}) {
  final kv = <String, String>{};
  void put(String k, Object? v) => kv[k] = v?.toString() ?? '';
  put('app_language', s.appLanguage.code);
  put('currency', s.currency.code);
  put('invoice_language', s.invoiceLanguageMode.code);
  put('numeral_format', s.numeralFormat.code);
  put('use_bikram_sambat', s.useBikramSambat);
  put('long_date_style', s.longDateStyle);
  put('show_time_on_receipt', s.showTimeOnReceipt);
  put('bottom_margin_on_receipt', s.bottomMarginOnReceipt);
  put('quantity_precision', s.quantityPrecision);
  put('invoice_prefix', s.invoicePrefix);
  put('fiscal_year_prefix', s.fiscalYearPrefix);
  put('invoice_digits', s.invoiceDigits);
  put('default_payment_method', s.defaultPaymentMethod);
  if (receiptProfile != null) {
    put('receipt_profile_id', receiptProfile.id);
    put('receipt_profile_name', receiptProfile.displayTitle(''));
  }
  return '{${kv.entries.map((e) => '"${e.key}":"${e.value}"').join(',')}}';
}
