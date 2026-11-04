/// Organization model with bilingual fields and a JSON snapshot format.
/// Historical invoices embed exact snapshots so later edits never silently
/// alter finalized receipts.
library;

import 'dart:convert';

class Organization {
  final int id;
  final String nameEn;
  final String nameNe;
  final String addressEn;
  final String addressNe;
  final String phone;
  final String alternativePhone;
  final String email;
  final String panNumber;
  final String vatNumber;
  final String registrationNumber;
  final String website;
  final String logoPath;
  final String customInfoEn;
  final String customInfoNe;
  final int createdAt;
  final int updatedAt;

  const Organization({
    required this.id,
    required this.nameEn,
    required this.nameNe,
    required this.addressEn,
    required this.addressNe,
    required this.phone,
    required this.alternativePhone,
    required this.email,
    required this.panNumber,
    required this.vatNumber,
    required this.registrationNumber,
    required this.website,
    required this.logoPath,
    required this.customInfoEn,
    required this.customInfoNe,
    required this.createdAt,
    required this.updatedAt,
  });

  static const empty = Organization(
    id: 0,
    nameEn: '',
    nameNe: '',
    addressEn: '',
    addressNe: '',
    phone: '',
    alternativePhone: '',
    email: '',
    panNumber: '',
    vatNumber: '',
    registrationNumber: '',
    website: '',
    logoPath: '',
    customInfoEn: '',
    customInfoNe: '',
    createdAt: 0,
    updatedAt: 0,
  );

  factory Organization.fromRow(Map<String, Object?> row) => Organization(
        id: row['id'] as int,
        nameEn: row['name_en'] as String? ?? '',
        nameNe: row['name_ne'] as String? ?? '',
        addressEn: row['address_en'] as String? ?? '',
        addressNe: row['address_ne'] as String? ?? '',
        phone: row['phone'] as String? ?? '',
        alternativePhone: row['alternative_phone'] as String? ?? '',
        email: row['email'] as String? ?? '',
        panNumber: row['pan_number'] as String? ?? '',
        vatNumber: row['vat_number'] as String? ?? '',
        registrationNumber: row['registration_number'] as String? ?? '',
        website: row['website'] as String? ?? '',
        logoPath: row['logo_path'] as String? ?? '',
        customInfoEn: row['custom_info_en'] as String? ?? '',
        customInfoNe: row['custom_info_ne'] as String? ?? '',
        createdAt: row['created_at'] as int? ?? 0,
        updatedAt: row['updated_at'] as int? ?? 0,
      );

  bool get isConfigured => nameEn.trim().isNotEmpty || nameNe.trim().isNotEmpty;

  String get displayName => nameEn.trim().isNotEmpty
      ? nameEn
      : (nameNe.trim().isNotEmpty ? nameNe : '');

  /// JSON snapshot stored on invoices.
  Map<String, Object?> toSnapshot() => {
        'name_en': nameEn,
        'name_ne': nameNe,
        'address_en': addressEn,
        'address_ne': addressNe,
        'phone': phone,
        'alternative_phone': alternativePhone,
        'email': email,
        'pan_number': panNumber,
        'vat_number': vatNumber,
        'registration_number': registrationNumber,
        'website': website,
        'custom_info_en': customInfoEn,
        'custom_info_ne': customInfoNe,
      };

  factory Organization.fromSnapshot(Map<String, Object?> s) => Organization(
        id: 0,
        nameEn: s['name_en'] as String? ?? '',
        nameNe: s['name_ne'] as String? ?? '',
        addressEn: s['address_en'] as String? ?? '',
        addressNe: s['address_ne'] as String? ?? '',
        phone: s['phone'] as String? ?? '',
        alternativePhone: s['alternative_phone'] as String? ?? '',
        email: s['email'] as String? ?? '',
        panNumber: s['pan_number'] as String? ?? '',
        vatNumber: s['vat_number'] as String? ?? '',
        registrationNumber: s['registration_number'] as String? ?? '',
        website: s['website'] as String? ?? '',
        logoPath: '',
        customInfoEn: s['custom_info_en'] as String? ?? '',
        customInfoNe: s['custom_info_ne'] as String? ?? '',
        createdAt: 0,
        updatedAt: 0,
      );

  String encodeSnapshot() => jsonEncode(toSnapshot());

  static Organization decodeSnapshot(String json) =>
      Organization.fromSnapshot(jsonDecode(json) as Map<String, Object?>);

  Map<String, Object?> toRow({bool withTimestamps = true}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      if (id > 0) 'id': id,
      'name_en': nameEn.trim(),
      'name_ne': nameNe.trim(),
      'address_en': addressEn.trim(),
      'address_ne': addressNe.trim(),
      'phone': phone.trim(),
      'alternative_phone': alternativePhone.trim(),
      'email': email.trim(),
      'pan_number': panNumber.trim(),
      'vat_number': vatNumber.trim(),
      'registration_number': registrationNumber.trim(),
      'website': website.trim(),
      'logo_path': logoPath,
      'custom_info_en': customInfoEn,
      'custom_info_ne': customInfoNe,
      if (withTimestamps) ...{
        'created_at': createdAt > 0 ? createdAt : now,
        'updated_at': now,
      },
    };
  }

  Organization copyWith({
    String? nameEn,
    String? nameNe,
    String? addressEn,
    String? addressNe,
    String? phone,
    String? alternativePhone,
    String? email,
    String? panNumber,
    String? vatNumber,
    String? registrationNumber,
    String? website,
    String? logoPath,
    String? customInfoEn,
    String? customInfoNe,
  }) =>
      Organization(
        id: id,
        nameEn: nameEn ?? this.nameEn,
        nameNe: nameNe ?? this.nameNe,
        addressEn: addressEn ?? this.addressEn,
        addressNe: addressNe ?? this.addressNe,
        phone: phone ?? this.phone,
        alternativePhone: alternativePhone ?? this.alternativePhone,
        email: email ?? this.email,
        panNumber: panNumber ?? this.panNumber,
        vatNumber: vatNumber ?? this.vatNumber,
        registrationNumber: registrationNumber ?? this.registrationNumber,
        website: website ?? this.website,
        logoPath: logoPath ?? this.logoPath,
        customInfoEn: customInfoEn ?? this.customInfoEn,
        customInfoNe: customInfoNe ?? this.customInfoNe,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
