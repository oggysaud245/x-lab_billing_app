/// App-wide settings model (stored as key/value rows).
library;

enum AppLanguage { en, ne }

enum InvoiceLanguageMode { followApp, en, ne }

enum NumeralFormat { western, devanagari }

enum ThemeChoice { system, light, dark }

enum CurrencySymbol { npr, ru }

extension AppLanguageX on AppLanguage {
  String get code => this == AppLanguage.en ? 'en' : 'ne';
  String get displayName => this == AppLanguage.en ? 'English' : 'नेपाली';
  bool get isNepali => this == AppLanguage.ne;
}

extension InvoiceLanguageModeX on InvoiceLanguageMode {
  String get code => switch (this) {
        InvoiceLanguageMode.followApp => 'follow',
        InvoiceLanguageMode.en => 'en',
        InvoiceLanguageMode.ne => 'ne',
      };
}

extension NumeralFormatX on NumeralFormat {
  String get code => this == NumeralFormat.western ? 'western' : 'devanagari';
  bool get isDevanagari => this == NumeralFormat.devanagari;
}

extension ThemeChoiceX on ThemeChoice {
  String get code => switch (this) {
        ThemeChoice.system => 'system',
        ThemeChoice.light => 'light',
        ThemeChoice.dark => 'dark',
      };
}

extension CurrencySymbolX on CurrencySymbol {
  String get code => this == CurrencySymbol.npr ? 'NPR' : 'ru';
  String get label => this == CurrencySymbol.npr ? 'NPR' : 'रु.';
}

class AppSettings {
  /// UI language (persisted, default from device locale at first launch).
  final AppLanguage appLanguage;
  final ThemeChoice theme;
  final CurrencySymbol currency;
  final InvoiceLanguageMode invoiceLanguageMode;
  final NumeralFormat numeralFormat;

  /// Calendar system used on receipts: AD (Gregorian) or BS (Bikram Sambat).
  final bool useBikramSambat;
  final bool longDateStyle;
  final bool showTimeOnReceipt;
  final bool bottomMarginOnReceipt;
  final int quantityPrecision;

  /// Numbering configuration.
  final String invoicePrefix;
  final bool fiscalYearPrefix;
  final int invoiceDigits;
  final int invoiceNext;

  /// Billing defaults.
  final int defaultDiscountPercent; // hundredths
  final bool taxEnabled;
  final int taxPercent; // hundredths
  final bool otherChargesEnabled;
  final String otherChargesNote;
  final String defaultPaymentMethod; // cash|qr|bank|other

  const AppSettings({
    required this.appLanguage,
    required this.theme,
    required this.currency,
    required this.invoiceLanguageMode,
    required this.numeralFormat,
    required this.useBikramSambat,
    required this.longDateStyle,
    required this.showTimeOnReceipt,
    this.bottomMarginOnReceipt = false,
    required this.quantityPrecision,
    required this.invoicePrefix,
    required this.fiscalYearPrefix,
    required this.invoiceDigits,
    required this.invoiceNext,
    required this.defaultDiscountPercent,
    required this.taxEnabled,
    required this.taxPercent,
    required this.otherChargesEnabled,
    required this.otherChargesNote,
    required this.defaultPaymentMethod,
  });

  static const defaults = AppSettings(
    appLanguage: AppLanguage.en,
    theme: ThemeChoice.system,
    currency: CurrencySymbol.npr,
    invoiceLanguageMode: InvoiceLanguageMode.followApp,
    numeralFormat: NumeralFormat.western,
    useBikramSambat: true,
    longDateStyle: true,
    showTimeOnReceipt: true,
    bottomMarginOnReceipt: false,
    quantityPrecision: 2,
    invoicePrefix: 'INV-',
    fiscalYearPrefix: false,
    invoiceDigits: 6,
    invoiceNext: 1,
    defaultDiscountPercent: 0,
    taxEnabled: false,
    taxPercent: 0,
    otherChargesEnabled: false,
    otherChargesNote: '',
    defaultPaymentMethod: 'cash',
  );

  AppSettings copyWith({
    AppLanguage? appLanguage,
    ThemeChoice? theme,
    CurrencySymbol? currency,
    InvoiceLanguageMode? invoiceLanguageMode,
    NumeralFormat? numeralFormat,
    bool? useBikramSambat,
    bool? longDateStyle,
    bool? showTimeOnReceipt,
    bool? bottomMarginOnReceipt,
    int? quantityPrecision,
    String? invoicePrefix,
    bool? fiscalYearPrefix,
    int? invoiceDigits,
    int? invoiceNext,
    int? defaultDiscountPercent,
    bool? taxEnabled,
    int? taxPercent,
    bool? otherChargesEnabled,
    String? otherChargesNote,
    String? defaultPaymentMethod,
  }) =>
      AppSettings(
        appLanguage: appLanguage ?? this.appLanguage,
        theme: theme ?? this.theme,
        currency: currency ?? this.currency,
        invoiceLanguageMode: invoiceLanguageMode ?? this.invoiceLanguageMode,
        numeralFormat: numeralFormat ?? this.numeralFormat,
        useBikramSambat: useBikramSambat ?? this.useBikramSambat,
        longDateStyle: longDateStyle ?? this.longDateStyle,
        showTimeOnReceipt: showTimeOnReceipt ?? this.showTimeOnReceipt,
        bottomMarginOnReceipt: bottomMarginOnReceipt ?? this.bottomMarginOnReceipt,
        quantityPrecision: quantityPrecision ?? this.quantityPrecision,
        invoicePrefix: invoicePrefix ?? this.invoicePrefix,
        fiscalYearPrefix: fiscalYearPrefix ?? this.fiscalYearPrefix,
        invoiceDigits: invoiceDigits ?? this.invoiceDigits,
        invoiceNext: invoiceNext ?? this.invoiceNext,
        defaultDiscountPercent: defaultDiscountPercent ?? this.defaultDiscountPercent,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        taxPercent: taxPercent ?? this.taxPercent,
        otherChargesEnabled: otherChargesEnabled ?? this.otherChargesEnabled,
        otherChargesNote: otherChargesNote ?? this.otherChargesNote,
        defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      );

  Map<String, String> toKeyValue() => {
        'app_language': appLanguage.code,
        'theme': theme.code,
        'currency': currency.code,
        'invoice_language': invoiceLanguageMode.code,
        'numeral_format': numeralFormat.code,
        'use_bikram_sambat': useBikramSambat ? '1' : '0',
        'long_date_style': longDateStyle ? '1' : '0',
        'show_time_on_receipt': showTimeOnReceipt ? '1' : '0',
        'bottom_margin_on_receipt': bottomMarginOnReceipt ? '1' : '0',
        'quantity_precision': quantityPrecision.toString(),
        'invoice_prefix': invoicePrefix,
        'fiscal_year_prefix': fiscalYearPrefix ? '1' : '0',
        'invoice_digits': invoiceDigits.toString(),
        'default_discount_percent': defaultDiscountPercent.toString(),
        'tax_enabled': taxEnabled ? '1' : '0',
        'tax_percent': taxPercent.toString(),
        'other_charges_enabled': otherChargesEnabled ? '1' : '0',
        'other_charges_note': otherChargesNote,
        'default_payment_method': defaultPaymentMethod,
      };

  factory AppSettings.fromKeyValue(Map<String, String> kv) {
    const d = AppSettings.defaults;
    String get(String key, String fallback) {
      final v = kv[key];
      return (v == null || v.isEmpty) ? fallback : v;
    }

    bool boolOf(String key, bool fallback) => get(key, fallback ? '1' : '0') == '1';
    int intOf(String key, int fallback) =>
        int.tryParse(get(key, fallback.toString())) ?? fallback;
    T enumOf<T extends Enum>(String key, List<T> values, T fallback, List<String> codes) {
      final code = get(key, '');
      for (var i = 0; i < codes.length; i++) {
        if (code == codes[i]) return values[i];
      }
      return fallback;
    }

    final appLang = enumOf('app_language', AppLanguage.values, d.appLanguage, ['en', 'ne']);
    return AppSettings(
      appLanguage: appLang,
      theme: enumOf('theme', ThemeChoice.values, d.theme, ['system', 'light', 'dark']),
      currency: appLang.isNepali ? CurrencySymbol.ru : CurrencySymbol.npr,
      invoiceLanguageMode: enumOf(
        'invoice_language',
        InvoiceLanguageMode.values,
        d.invoiceLanguageMode,
        ['follow', 'en', 'ne'],
      ),
      numeralFormat: appLang.isNepali ? NumeralFormat.devanagari : NumeralFormat.western,
      useBikramSambat: boolOf('use_bikram_sambat', d.useBikramSambat),
      longDateStyle: boolOf('long_date_style', d.longDateStyle),
      showTimeOnReceipt: boolOf('show_time_on_receipt', d.showTimeOnReceipt),
      bottomMarginOnReceipt: boolOf('bottom_margin_on_receipt', d.bottomMarginOnReceipt),
      quantityPrecision: intOf('quantity_precision', d.quantityPrecision),
      invoicePrefix: get('invoice_prefix', d.invoicePrefix),
      fiscalYearPrefix: boolOf('fiscal_year_prefix', d.fiscalYearPrefix),
      invoiceDigits: intOf('invoice_digits', d.invoiceDigits),
      defaultDiscountPercent: intOf('default_discount_percent', d.defaultDiscountPercent),
      taxEnabled: boolOf('tax_enabled', d.taxEnabled),
      taxPercent: intOf('tax_percent', d.taxPercent),
      otherChargesEnabled: boolOf('other_charges_enabled', d.otherChargesEnabled),
      otherChargesNote: get('other_charges_note', d.otherChargesNote),
      defaultPaymentMethod: get('default_payment_method', d.defaultPaymentMethod),
      invoiceNext: intOf('invoice_next', d.invoiceNext),
    );
  }
}
