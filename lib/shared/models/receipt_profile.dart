/// Bundled receipt profile: organization details, receipt language/date/margin
/// options, and receipt template design (header/footer messages, visible
/// fields, alignment, text size). Allows users to maintain multiple receipt
/// configurations on the same device and switch between them.
library;

import 'dart:convert';

import 'app_settings.dart';
import 'organization.dart';
import 'receipt_settings.dart';

class ReceiptProfile {
  final String id;
  final String name;
  final Organization organization;
  final InvoiceLanguageMode invoiceLanguageMode;
  final bool useBikramSambat;
  final bool longDateStyle;
  final bool showTimeOnReceipt;
  final bool bottomMarginOnReceipt;
  final ReceiptSettings receipt;

  const ReceiptProfile({
    required this.id,
    required this.name,
    required this.organization,
    this.invoiceLanguageMode = InvoiceLanguageMode.followApp,
    this.useBikramSambat = true,
    this.longDateStyle = true,
    this.showTimeOnReceipt = true,
    this.bottomMarginOnReceipt = false,
    required this.receipt,
  });

  static const emptyDefault = ReceiptProfile(
    id: 'profile_1',
    name: '',
    organization: Organization.empty,
    invoiceLanguageMode: InvoiceLanguageMode.followApp,
    useBikramSambat: true,
    longDateStyle: true,
    showTimeOnReceipt: true,
    bottomMarginOnReceipt: false,
    receipt: ReceiptSettings.defaults,
  );

  String displayTitle(String fallback) {
    if (name.trim().isNotEmpty) return name.trim();
    if (organization.displayName.trim().isNotEmpty) {
      return organization.displayName.trim();
    }
    return fallback;
  }

  ReceiptProfile copyWith({
    String? id,
    String? name,
    Organization? organization,
    InvoiceLanguageMode? invoiceLanguageMode,
    bool? useBikramSambat,
    bool? longDateStyle,
    bool? showTimeOnReceipt,
    bool? bottomMarginOnReceipt,
    ReceiptSettings? receipt,
  }) =>
      ReceiptProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        organization: organization ?? this.organization,
        invoiceLanguageMode: invoiceLanguageMode ?? this.invoiceLanguageMode,
        useBikramSambat: useBikramSambat ?? this.useBikramSambat,
        longDateStyle: longDateStyle ?? this.longDateStyle,
        showTimeOnReceipt: showTimeOnReceipt ?? this.showTimeOnReceipt,
        bottomMarginOnReceipt:
            bottomMarginOnReceipt ?? this.bottomMarginOnReceipt,
        receipt: receipt ?? this.receipt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'organization': organization.toRow(withTimestamps: false),
        'invoice_language': invoiceLanguageMode.code,
        'use_bikram_sambat': useBikramSambat,
        'long_date_style': longDateStyle,
        'show_time_on_receipt': showTimeOnReceipt,
        'bottom_margin_on_receipt': bottomMarginOnReceipt,
        'receipt': receipt.toRow(),
      };

  factory ReceiptProfile.fromJson(Map<String, Object?> j) {
    final orgRaw = j['organization'];
    final orgMap = orgRaw is Map
        ? orgRaw.map((k, v) => MapEntry(k.toString(), v))
        : <String, Object?>{};
    final rcRaw = j['receipt'];
    final rcMap = rcRaw is Map
        ? rcRaw.map((k, v) => MapEntry(k.toString(), v))
        : <String, Object?>{};
    final langCode = j['invoice_language'] as String? ?? 'follow';
    final invLang = switch (langCode) {
      'en' => InvoiceLanguageMode.en,
      'ne' => InvoiceLanguageMode.ne,
      _ => InvoiceLanguageMode.followApp,
    };
    return ReceiptProfile(
      id: (j['id'] as String? ?? '').isEmpty ? 'profile_1' : (j['id'] as String),
      name: j['name'] as String? ?? '',
      organization: Organization.fromRow({
        'id': 1,
        ...orgMap,
      }),
      invoiceLanguageMode: invLang,
      useBikramSambat: j['use_bikram_sambat'] as bool? ?? true,
      longDateStyle: j['long_date_style'] as bool? ?? true,
      showTimeOnReceipt: j['show_time_on_receipt'] as bool? ?? true,
      bottomMarginOnReceipt: j['bottom_margin_on_receipt'] as bool? ?? false,
      receipt: ReceiptSettings.fromRow({
        'id': 1,
        ...rcMap,
      }),
    );
  }

  static String encodeList(List<ReceiptProfile> profiles) =>
      jsonEncode([for (final p in profiles) p.toJson()]);

  static List<ReceiptProfile> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return [
          for (final item in decoded)
            if (item is Map)
              ReceiptProfile.fromJson(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ),
        ];
      }
    } catch (_) {}
    return [];
  }
}

