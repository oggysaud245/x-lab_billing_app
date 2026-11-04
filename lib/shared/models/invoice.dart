/// Invoice models: cart lines, totals computation, finalized invoice and
/// item snapshots.
library;

import 'dart:convert';

import '../../core/formatting/money.dart' as money;
import 'receipt_profile.dart';

enum DiscountType { none, percent, fixed }

extension DiscountTypeX on DiscountType {
  String get code => switch (this) {
        DiscountType.none => 'none',
        DiscountType.percent => 'percent',
        DiscountType.fixed => 'fixed',
      };
}

/// Parses a stored code.
DiscountType discountTypeFromCode(String code) => switch (code) {
      'percent' => DiscountType.percent,
      'fixed' => DiscountType.fixed,
      _ => DiscountType.none,
    };

enum InvoiceStatus {
  processing,
  success,
  canceled;

  static const InvoiceStatus finalized = InvoiceStatus.success;
  static const InvoiceStatus voided = InvoiceStatus.canceled;
}

extension InvoiceStatusX on InvoiceStatus {
  String get code => switch (this) {
        InvoiceStatus.processing => 'processing',
        InvoiceStatus.success => 'success',
        InvoiceStatus.canceled => 'canceled',
      };
}

InvoiceStatus invoiceStatusFromCode(String code) => switch (code.toLowerCase()) {
      'processing' => InvoiceStatus.processing,
      'canceled' || 'voided' => InvoiceStatus.canceled,
      'success' || 'finalized' => InvoiceStatus.success,
      _ => InvoiceStatus.success,
    };

/// Payment methods: cash is the verified/default method; the others are
/// informational entries recorded on the invoice (no digital-payment
/// integration is claimed).
enum PaymentMethod { cash, qr, bankTransfer, other }

extension PaymentMethodX on PaymentMethod {
  String get code => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.qr => 'qr',
        PaymentMethod.bankTransfer => 'bankTransfer',
        PaymentMethod.other => 'other',
      };
}

/// Parses a stored code; cash is the default for unknown/legacy values.
PaymentMethod paymentMethodFromCode(String? code) => switch (code) {
      'qr' => PaymentMethod.qr,
      'bankTransfer' => PaymentMethod.bankTransfer,
      'other' => PaymentMethod.other,
      _ => PaymentMethod.cash,
    };

class CustomerInfo {
  final String name;
  final String phone;
  final String address;

  const CustomerInfo({this.name = '', this.phone = '', this.address = ''});

  bool get isEmpty => name.isEmpty && phone.isEmpty && address.isEmpty;

  Map<String, String> toJson() => {'name': name, 'phone': phone, 'address': address};

  factory CustomerInfo.fromJson(Map<String, Object?> j) => CustomerInfo(
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
      );

  String encode() => jsonEncode(toJson());

  static CustomerInfo decode(String json) =>
      CustomerInfo.fromJson(jsonDecode(json) as Map<String, Object?>);
}

/// A line of the working bill (not yet finalized).
class CartLine {
  final int? productId;
  final String nameEn;
  final String nameNe;
  final String skuSnapshot;
  final String unitSnapshotEn;
  final String unitSnapshotNe;
  final int quantityMilli;
  final int ratePaisa;
  final int position;
  final int? quantityPrecision;
  final DiscountType discountType = DiscountType.none; // per-line discounts not supported

  const CartLine({
    required this.productId,
    required this.nameEn,
    required this.nameNe,
    required this.skuSnapshot,
    required this.unitSnapshotEn,
    required this.unitSnapshotNe,
    required this.quantityMilli,
    required this.ratePaisa,
    this.position = 0,
    this.quantityPrecision,
  });

  int get lineTotalPaisa =>
      money.lineTotalPaisa(quantityMilli, ratePaisa, precision: quantityPrecision);

  static int lineTotalOf(int quantityMilli, int ratePaisa, {int? precision}) =>
      money.lineTotalPaisa(quantityMilli, ratePaisa, precision: precision);

  CartLine copyWith({int? quantityMilli, int? quantityPrecision}) => CartLine(
        productId: productId,
        nameEn: nameEn,
        nameNe: nameNe,
        skuSnapshot: skuSnapshot,
        unitSnapshotEn: unitSnapshotEn,
        unitSnapshotNe: unitSnapshotNe,
        quantityMilli: quantityMilli ?? this.quantityMilli,
        ratePaisa: ratePaisa,
        position: position,
        quantityPrecision: quantityPrecision ?? this.quantityPrecision,
      );
}

/// Computed totals for a bill.
class BillTotals {
  final int subtotalPaisa;
  final DiscountType discountType;
  final int discountValue; // percent (x100) or fixed paisa
  final int discountAmount;
  final int taxRate; // hundredths
  final int taxAmount;
  final int otherCharges;
  final int grandTotal;
  final int amountPaid;
  final int balanceDue;

  const BillTotals({
    required this.subtotalPaisa,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.otherCharges,
    required this.grandTotal,
    required this.amountPaid,
    required this.balanceDue,
  });

  static BillTotals compute(
    Iterable<CartLine> lines, {
    DiscountType discountType = DiscountType.none,
    int discountValue = 0,
    int taxRate = 0,
    int otherCharges = 0,
    int amountPaid = 0,
    int? quantityPrecision,
  }) {
    var subtotal = 0;
    for (final l in lines) {
      final p = quantityPrecision ?? l.quantityPrecision;
      subtotal += p != null
          ? money.lineTotalPaisa(l.quantityMilli, l.ratePaisa, precision: p)
          : l.lineTotalPaisa;
    }
    if (subtotal < 0) subtotal = 0;
    var discountAmount = switch (discountType) {
      DiscountType.none => 0,
      DiscountType.percent => money.percentOfPaisa(subtotal, discountValue),
      DiscountType.fixed => discountValue,
    };
    if (discountAmount > subtotal) discountAmount = subtotal;
    final taxable = subtotal - discountAmount;
    var taxAmount = taxRate > 0 ? money.percentOfPaisa(taxable, taxRate) : 0;
    var other = otherCharges < 0 ? 0 : otherCharges;
    var grandTotal = subtotal - discountAmount + taxAmount + other;
    if (grandTotal < 0) grandTotal = 0;
    final paid = amountPaid < 0 ? 0 : amountPaid;
    final due = grandTotal - paid; // negative due means change to return
    return BillTotals(
      subtotalPaisa: subtotal,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      taxRate: taxRate,
      taxAmount: taxAmount,
      otherCharges: other,
      grandTotal: grandTotal,
      amountPaid: paid,
      balanceDue: due,
    );
  }
}

/// A finalized invoice (with stored snapshots for history/reprint).
class Invoice {
  final int id;
  final String invoiceNumber;
  final int invoiceNumberSeq;
  final int createdAt;
  final String orgSnapshotJson;
  final String receiptSnapshotJson;
  final String appSettingsSnapshotJson;
  final InvoiceLanguage invoiceLanguage;
  final String dateSystem; // 'ad' | 'bs'
  final String dateStyle; // 'numeric' | 'long'
  final String numeralFormat; // 'western' | 'devanagari'
  final CustomerInfo? customer;
  final List<InvoiceItem> items;
  final BillTotals totals;
  final PaymentMethod paymentMethod;
  final String otherChargesNote;
  final String notes;
  final InvoiceStatus status;
  final String statusNote;
  final int printCount;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceNumberSeq,
    required this.createdAt,
    required this.orgSnapshotJson,
    required this.receiptSnapshotJson,
    required this.appSettingsSnapshotJson,
    required this.invoiceLanguage,
    required this.dateSystem,
    required this.dateStyle,
    required this.numeralFormat,
    required this.customer,
    required this.items,
    required this.totals,
    required this.paymentMethod,
    required this.otherChargesNote,
    required this.notes,
    required this.status,
    required this.statusNote,
    required this.printCount,
  });

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? invoiceNumberSeq,
    List<InvoiceItem>? items,
    int? printCount,
  }) =>
      Invoice(
        id: id ?? this.id,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        invoiceNumberSeq: invoiceNumberSeq ?? this.invoiceNumberSeq,
        createdAt: createdAt,
        orgSnapshotJson: orgSnapshotJson,
        receiptSnapshotJson: receiptSnapshotJson,
        appSettingsSnapshotJson: appSettingsSnapshotJson,
        invoiceLanguage: invoiceLanguage,
        dateSystem: dateSystem,
        dateStyle: dateStyle,
        numeralFormat: numeralFormat,
        customer: customer,
        items: items ?? this.items,
        totals: totals,
        paymentMethod: paymentMethod,
        otherChargesNote: otherChargesNote,
        notes: notes,
        status: status,
        statusNote: statusNote,
        printCount: printCount ?? this.printCount,
      );

  String? get receiptProfileId {
    try {
      final snap = jsonDecode(receiptSnapshotJson) as Map<String, Object?>?;
      final id = snap?['profile_id'] as String?;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    try {
      final snap = jsonDecode(appSettingsSnapshotJson) as Map<String, Object?>?;
      final id = snap?['receipt_profile_id'] as String?;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return null;
  }

  String? get receiptProfileName {
    try {
      final snap = jsonDecode(receiptSnapshotJson) as Map<String, Object?>?;
      final name = snap?['profile_name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    try {
      final snap = jsonDecode(appSettingsSnapshotJson) as Map<String, Object?>?;
      final name = snap?['receipt_profile_name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return null;
  }

  String profileDisplayTitle(List<ReceiptProfile> profiles, String fallback) {
    final direct = receiptProfileName;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();

    final id = receiptProfileId;
    if (id != null && id.isNotEmpty) {
      final match = profiles.where((p) => p.id == id).firstOrNull;
      if (match != null) return match.displayTitle(fallback);
    }

    try {
      final orgSnap = jsonDecode(orgSnapshotJson) as Map<String, Object?>?;
      if (orgSnap != null) {
        final pan = (orgSnap['pan_number'] as String? ?? '').trim();
        final nameEn = (orgSnap['name_en'] as String? ?? '').trim();
        final nameNe = (orgSnap['name_ne'] as String? ?? '').trim();
        for (final p in profiles) {
          if (pan.isNotEmpty && p.organization.panNumber.trim() == pan) {
            return p.displayTitle(fallback);
          }
          if (nameEn.isNotEmpty && p.organization.nameEn.trim() == nameEn) {
            return p.displayTitle(fallback);
          }
          if (nameNe.isNotEmpty && p.organization.nameNe.trim() == nameNe) {
            return p.displayTitle(fallback);
          }
        }
      }
    } catch (_) {}

    if (profiles.isNotEmpty) {
      return profiles.first.displayTitle(fallback);
    }
    return fallback;
  }

  bool matchesReceiptProfile(ReceiptProfile p, List<ReceiptProfile> allProfiles) {
    final id = receiptProfileId;
    if (id != null && id.isNotEmpty) {
      return id == p.id;
    }
    try {
      final orgSnap = jsonDecode(orgSnapshotJson) as Map<String, Object?>?;
      if (orgSnap != null) {
        final pan = (orgSnap['pan_number'] as String? ?? '').trim();
        final nameEn = (orgSnap['name_en'] as String? ?? '').trim();
        final nameNe = (orgSnap['name_ne'] as String? ?? '').trim();
        if (pan.isNotEmpty &&
            p.organization.panNumber.trim().isNotEmpty &&
            pan == p.organization.panNumber.trim()) {
          return true;
        }
        if (nameEn.isNotEmpty &&
            p.organization.nameEn.trim().isNotEmpty &&
            nameEn == p.organization.nameEn.trim()) {
          return true;
        }
        if (nameNe.isNotEmpty &&
            p.organization.nameNe.trim().isNotEmpty &&
            nameNe == p.organization.nameNe.trim()) {
          return true;
        }
      }
    } catch (_) {}

    if (allProfiles.isNotEmpty && allProfiles.first.id == p.id) {
      for (final other in allProfiles) {
        if (other.id == p.id) continue;
        if (matchesReceiptProfile(other, const [])) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

enum InvoiceLanguage { en, ne }

extension InvoiceLanguageX on InvoiceLanguage {
  String get code => this == InvoiceLanguage.en ? 'en' : 'ne';
  bool get nepali => this == InvoiceLanguage.ne;
}

/// Parses a stored code; English is the fallback.
InvoiceLanguage invoiceLanguageFromCode(String code) =>
    code == 'ne' ? InvoiceLanguage.ne : InvoiceLanguage.en;

class InvoiceItem {
  final int id;
  final int? productId;
  final String nameSnapshotEn;
  final String nameSnapshotNe;
  final String skuSnapshot;
  final String unitSnapshotEn;
  final String unitSnapshotNe;
  final int quantityMilli;
  final int ratePaisa;
  final int lineTotalPaisa;
  final int position;

  const InvoiceItem({
    required this.id,
    required this.productId,
    required this.nameSnapshotEn,
    required this.nameSnapshotNe,
    required this.skuSnapshot,
    required this.unitSnapshotEn,
    required this.unitSnapshotNe,
    required this.quantityMilli,
    required this.ratePaisa,
    required this.lineTotalPaisa,
    required this.position,
  });

  factory InvoiceItem.fromRow(Map<String, Object?> r) => InvoiceItem(
        id: r['id'] as int,
        productId: r['product_id'] as int?,
        nameSnapshotEn: r['name_snapshot_en'] as String? ?? '',
        nameSnapshotNe: r['name_snapshot_ne'] as String? ?? '',
        skuSnapshot: r['sku_snapshot'] as String? ?? '',
        unitSnapshotEn: r['unit_snapshot_en'] as String? ?? '',
        unitSnapshotNe: r['unit_snapshot_ne'] as String? ?? '',
        quantityMilli: r['quantity_milli'] as int? ?? 0,
        ratePaisa: r['rate_paisa'] as int? ?? 0,
        lineTotalPaisa: r['line_total_paisa'] as int? ?? 0,
        position: r['position'] as int? ?? 0,
      );

  Map<String, Object?> toRow(int invoiceId) => {
        'invoice_id': invoiceId,
        'product_id': productId,
        'name_snapshot_en': nameSnapshotEn,
        'name_snapshot_ne': nameSnapshotNe,
        'sku_snapshot': skuSnapshot,
        'unit_snapshot_en': unitSnapshotEn,
        'unit_snapshot_ne': unitSnapshotNe,
        'quantity_milli': quantityMilli,
        'rate_paisa': ratePaisa,
        'line_total_paisa': lineTotalPaisa,
        'position': position,
      };
}

