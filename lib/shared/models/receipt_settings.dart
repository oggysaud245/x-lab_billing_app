/// Receipt header/footer design settings (single row, id = 1).
/// Custom messages are stored for both languages; empty fields fall back to
/// localized default texts.
library;

import 'dart:convert';

enum ReceiptHeaderAlign { left, center }

extension ReceiptHeaderAlignX on ReceiptHeaderAlign {
  String get code => this == ReceiptHeaderAlign.left ? 'left' : 'center';
}

enum ReceiptTextSize { small, normal, large }

extension ReceiptTextSizeX on ReceiptTextSize {
  String get code => switch (this) {
        ReceiptTextSize.small => 'small',
        ReceiptTextSize.normal => 'normal',
        ReceiptTextSize.large => 'large',
      };
}

class ReceiptMessages {
  final String welcome;
  final String thank;
  final String policy;
  final String terms;
  final String promo;
  final String extra;

  const ReceiptMessages({
    this.welcome = '',
    this.thank = '',
    this.policy = '',
    this.terms = '',
    this.promo = '',
    this.extra = '',
  });
}

class ReceiptSettings {
  final int id;
  final String logoPath;

  final ReceiptHeaderAlign headerAlign;
  final ReceiptTextSize textSize;

  final String welcomeEn;
  final String welcomeNe;
  final String thankEn;
  final String thankNe;
  final String policyEn;
  final String policyNe;
  final String termsEn;
  final String termsNe;
  final String promoEn;
  final String promoNe;
  final String extraEn;
  final String extraNe;

  final bool showLogo;
  final bool showAddress;
  final bool showPhone;
  final bool showEmail;
  final bool showWebsite;
  final bool showPanVat;
  final bool showCustomer;
  final bool showPayment;

  const ReceiptSettings({
    required this.id,
    required this.logoPath,
    required this.headerAlign,
    required this.textSize,
    required this.welcomeEn,
    required this.welcomeNe,
    required this.thankEn,
    required this.thankNe,
    required this.policyEn,
    required this.policyNe,
    required this.termsEn,
    required this.termsNe,
    required this.promoEn,
    required this.promoNe,
    required this.extraEn,
    required this.extraNe,
    required this.showLogo,
    required this.showAddress,
    required this.showPhone,
    required this.showEmail,
    required this.showWebsite,
    required this.showPanVat,
    required this.showCustomer,
    required this.showPayment,
  });

  static const defaults = ReceiptSettings(
    id: 1,
    logoPath: '',
    headerAlign: ReceiptHeaderAlign.center,
    textSize: ReceiptTextSize.normal,
    welcomeEn: '',
    welcomeNe: '',
    thankEn: '',
    thankNe: '',
    policyEn: '',
    policyNe: '',
    termsEn: '',
    termsNe: '',
    promoEn: '',
    promoNe: '',
    extraEn: '',
    extraNe: '',
    showLogo: false,
    showAddress: true,
    showPhone: true,
    showEmail: false,
    showWebsite: false,
    showPanVat: true,
    showCustomer: true,
    showPayment: true,
  );

  factory ReceiptSettings.fromRow(Map<String, Object?> row) => ReceiptSettings(
        id: row['id'] as int? ?? 1,
        logoPath: row['logo_path'] as String? ?? '',
        headerAlign: (row['header_align'] as String? ?? 'center') == 'left'
            ? ReceiptHeaderAlign.left
            : ReceiptHeaderAlign.center,
        textSize: switch (row['text_size'] as String? ?? 'normal') {
          'small' => ReceiptTextSize.small,
          'large' => ReceiptTextSize.large,
          _ => ReceiptTextSize.normal,
        },
        welcomeEn: row['welcome_en'] as String? ?? '',
        welcomeNe: row['welcome_ne'] as String? ?? '',
        thankEn: row['thank_en'] as String? ?? '',
        thankNe: row['thank_ne'] as String? ?? '',
        policyEn: row['policy_en'] as String? ?? '',
        policyNe: row['policy_ne'] as String? ?? '',
        termsEn: row['terms_en'] as String? ?? '',
        termsNe: row['terms_ne'] as String? ?? '',
        promoEn: row['promo_en'] as String? ?? '',
        promoNe: row['promo_ne'] as String? ?? '',
        extraEn: row['extra_en'] as String? ?? '',
        extraNe: row['extra_ne'] as String? ?? '',
        showLogo: (row['show_logo'] as int? ?? 0) != 0,
        showAddress: (row['show_address'] as int? ?? 1) != 0,
        showPhone: (row['show_phone'] as int? ?? 1) != 0,
        showEmail: (row['show_email'] as int? ?? 0) != 0,
        showWebsite: (row['show_website'] as int? ?? 0) != 0,
        showPanVat: (row['show_pan_vat'] as int? ?? 1) != 0,
        showCustomer: (row['show_customer'] as int? ?? 1) != 0,
        showPayment: (row['show_payment'] as int? ?? 1) != 0,
      );

  Map<String, Object?> toRow() => {
        if (id > 0) 'id': id,
        'logo_path': logoPath,
        'header_align': headerAlign.code,
        'text_size': textSize.code,
        'welcome_en': welcomeEn,
        'welcome_ne': welcomeNe,
        'thank_en': thankEn,
        'thank_ne': thankNe,
        'policy_en': policyEn,
        'policy_ne': policyNe,
        'terms_en': termsEn,
        'terms_ne': termsNe,
        'promo_en': promoEn,
        'promo_ne': promoNe,
        'extra_en': extraEn,
        'extra_ne': extraNe,
        'show_logo': showLogo ? 1 : 0,
        'show_address': showAddress ? 1 : 0,
        'show_phone': showPhone ? 1 : 0,
        'show_email': showEmail ? 1 : 0,
        'show_website': showWebsite ? 1 : 0,
        'show_pan_vat': showPanVat ? 1 : 0,
        'show_customer': showCustomer ? 1 : 0,
        'show_payment': showPayment ? 1 : 0,
      };

  ReceiptSettings copyWith({
    String? logoPath,
    ReceiptHeaderAlign? headerAlign,
    ReceiptTextSize? textSize,
    String? welcomeEn,
    String? welcomeNe,
    String? thankEn,
    String? thankNe,
    String? policyEn,
    String? policyNe,
    String? termsEn,
    String? termsNe,
    String? promoEn,
    String? promoNe,
    String? extraEn,
    String? extraNe,
    bool? showLogo,
    bool? showAddress,
    bool? showPhone,
    bool? showEmail,
    bool? showWebsite,
    bool? showPanVat,
    bool? showCustomer,
    bool? showPayment,
  }) =>
      ReceiptSettings(
        id: id,
        logoPath: logoPath ?? this.logoPath,
        headerAlign: headerAlign ?? this.headerAlign,
        textSize: textSize ?? this.textSize,
        welcomeEn: welcomeEn ?? this.welcomeEn,
        welcomeNe: welcomeNe ?? this.welcomeNe,
        thankEn: thankEn ?? this.thankEn,
        thankNe: thankNe ?? this.thankNe,
        policyEn: policyEn ?? this.policyEn,
        policyNe: policyNe ?? this.policyNe,
        termsEn: termsEn ?? this.termsEn,
        termsNe: termsNe ?? this.termsNe,
        promoEn: promoEn ?? this.promoEn,
        promoNe: promoNe ?? this.promoNe,
        extraEn: extraEn ?? this.extraEn,
        extraNe: extraNe ?? this.extraNe,
        showLogo: showLogo ?? this.showLogo,
        showAddress: showAddress ?? this.showAddress,
        showPhone: showPhone ?? this.showPhone,
        showEmail: showEmail ?? this.showEmail,
        showWebsite: showWebsite ?? this.showWebsite,
        showPanVat: showPanVat ?? this.showPanVat,
        showCustomer: showCustomer ?? this.showCustomer,
        showPayment: showPayment ?? this.showPayment,
      );

  /// Language-specific messages.
  ReceiptMessages messages({required bool nepali}) => nepali
      ? ReceiptMessages(
          welcome: welcomeNe,
          thank: thankNe,
          policy: policyNe,
          terms: termsNe,
          promo: promoNe,
          extra: extraNe,
        )
      : ReceiptMessages(
          welcome: welcomeEn,
          thank: thankEn,
          policy: policyEn,
          terms: termsEn,
          promo: promoEn,
          extra: extraEn,
        );

  String encodeSnapshot() => jsonEncode(toRow());

  factory ReceiptSettings.decodeSnapshot(String json) =>
      ReceiptSettings.fromRow(jsonDecode(json) as Map<String, Object?>);
}
