/// Billing profile: bundles tax settings, default discount, default payment
/// method, other-charges defaults, and invoice numbering (prefix, digits,
/// fiscal-year prefix) into a named profile so users can switch between
/// multiple billing setups (e.g. Retail 13% VAT, Wholesale Tax-Free, Counter 2).
library;

import 'dart:convert';

class BillingProfile {
  final String id;
  final String name;
  final bool taxEnabled;
  final int taxPercent; // hundredths (e.g. 1300 = 13.00%)
  final int defaultDiscountPercent; // whole percent (0, 1, 2, 3, 5, 10, 20, 50)
  final bool otherChargesEnabled;
  final String otherChargesNote;
  final String defaultPaymentMethod; // cash|qr|bank|other
  final String invoicePrefix;
  final int invoiceDigits;
  final bool fiscalYearPrefix;

  const BillingProfile({
    required this.id,
    required this.name,
    this.taxEnabled = false,
    this.taxPercent = 0,
    this.defaultDiscountPercent = 0,
    this.otherChargesEnabled = false,
    this.otherChargesNote = '',
    this.defaultPaymentMethod = 'cash',
    this.invoicePrefix = 'INV-',
    this.invoiceDigits = 6,
    this.fiscalYearPrefix = false,
  });

  static const emptyDefault = BillingProfile(
    id: 'billing_1',
    name: '',
  );

  String displayTitle(String fallback) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final prefix = invoicePrefix.trim();
    if (prefix.isNotEmpty && prefix != 'INV-') return prefix;
    return fallback;
  }

  BillingProfile copyWith({
    String? id,
    String? name,
    bool? taxEnabled,
    int? taxPercent,
    int? defaultDiscountPercent,
    bool? otherChargesEnabled,
    String? otherChargesNote,
    String? defaultPaymentMethod,
    String? invoicePrefix,
    int? invoiceDigits,
    bool? fiscalYearPrefix,
  }) =>
      BillingProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        taxPercent: taxPercent ?? this.taxPercent,
        defaultDiscountPercent:
            defaultDiscountPercent ?? this.defaultDiscountPercent,
        otherChargesEnabled: otherChargesEnabled ?? this.otherChargesEnabled,
        otherChargesNote: otherChargesNote ?? this.otherChargesNote,
        defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
        invoicePrefix: invoicePrefix ?? this.invoicePrefix,
        invoiceDigits: invoiceDigits ?? this.invoiceDigits,
        fiscalYearPrefix: fiscalYearPrefix ?? this.fiscalYearPrefix,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'tax_enabled': taxEnabled,
        'tax_percent': taxPercent,
        'default_discount_percent': defaultDiscountPercent,
        'other_charges_enabled': otherChargesEnabled,
        'other_charges_note': otherChargesNote,
        'default_payment_method': defaultPaymentMethod,
        'invoice_prefix': invoicePrefix,
        'invoice_digits': invoiceDigits,
        'fiscal_year_prefix': fiscalYearPrefix,
      };

  factory BillingProfile.fromJson(Map<String, Object?> json) {
    bool boolVal(String key, bool fallback) {
      final v = json[key];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return fallback;
    }

    int intVal(String key, int fallback) {
      final v = json[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    String strVal(String key, String fallback) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return v;
      return fallback;
    }

    return BillingProfile(
      id: (json['id'] as String?) ?? 'billing_1',
      name: (json['name'] as String?) ?? '',
      taxEnabled: boolVal('tax_enabled', false),
      taxPercent: intVal('tax_percent', 0),
      defaultDiscountPercent: intVal('default_discount_percent', 0),
      otherChargesEnabled: boolVal('other_charges_enabled', false),
      otherChargesNote: (json['other_charges_note'] as String?) ?? '',
      defaultPaymentMethod: strVal('default_payment_method', 'cash'),
      invoicePrefix: strVal('invoice_prefix', 'INV-'),
      invoiceDigits: intVal('invoice_digits', 6).clamp(1, 12),
      fiscalYearPrefix: boolVal('fiscal_year_prefix', false),
    );
  }

  static String encodeList(List<BillingProfile> profiles) =>
      jsonEncode(profiles.map((p) => p.toJson()).toList());

  static List<BillingProfile> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is Map<String, Object?>) BillingProfile.fromJson(item),
      ];
    } catch (_) {
      return const [];
    }
  }
}

