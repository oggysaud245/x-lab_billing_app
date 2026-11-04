/// Unit of measurement with bilingual names/abbreviations.
library;

import '../../core/db/app_database.dart';

class Unit {
  final int id;
  final String nameEn;
  final String nameNe;
  final String abbrevEn;
  final String abbrevNe;
  final bool isCustom;

  const Unit({
    required this.id,
    required this.nameEn,
    required this.nameNe,
    required this.abbrevEn,
    required this.abbrevNe,
    required this.isCustom,
  });

  factory Unit.fromRow(Map<String, Object?> row) => Unit(
        id: row['id'] as int,
        nameEn: row['name_en'] as String? ?? '',
        nameNe: row['name_ne'] as String? ?? '',
        abbrevEn: row['abbrev_en'] as String? ?? '',
        abbrevNe: row['abbrev_ne'] as String? ?? '',
        isCustom: (row['is_custom'] as int? ?? 0) != 0,
      );

  /// English (or fallback) display name.
  String get displayEn => abbrevEn.isNotEmpty
      ? abbrevEn
      : (nameEn.isNotEmpty ? nameEn : (nameNe.isNotEmpty ? nameNe : '×'));

  /// Nepali (or fallback to English) display name.
  String get displayNe => abbrevNe.isNotEmpty
      ? abbrevNe
      : (nameNe.isNotEmpty
          ? nameNe
          : (abbrevEn.isNotEmpty ? abbrevEn : (nameEn.isNotEmpty ? nameEn : '×')));

  /// Last-resort fallback that never renders empty.
  String get fallback => displayEn == '×' ? '' : displayEn;

  bool get isUsable =>
      isCustom
          ? (nameNonEmpty(nameEn) || nameNonEmpty(nameNe))
          : true;

  static bool nameNonEmpty(String s) => s.trim().isNotEmpty;

  /// Display name for [nepali] UIs with the other language as fallback.
  String displayName({bool nepali = false}) => nepali ? displayNe : displayEn;

  Unit copyWith({
    int? id,
    String? nameEn,
    String? nameNe,
    String? abbrevEn,
    String? abbrevNe,
    bool? isCustom,
  }) =>
      Unit(
        id: id ?? this.id,
        nameEn: nameEn ?? this.nameEn,
        nameNe: nameNe ?? this.nameNe,
        abbrevEn: abbrevEn ?? this.abbrevEn,
        abbrevNe: abbrevNe ?? this.abbrevNe,
        isCustom: isCustom ?? this.isCustom,
      );
}

/// Resolves a short unit representation (abbreviation if available) in either
/// English or Nepali, mapping common names/abbreviations across languages.
String shortUnit(String unit, {bool nepali = false}) {
  final u = unit.trim();
  if (u.isEmpty) return '';
  for (final (nameEn, nameNe, abbrevEn, abbrevNe) in defaultUnits) {
    final matchesEn = u.toLowerCase() == nameEn.toLowerCase() ||
        (abbrevEn.isNotEmpty && u.toLowerCase() == abbrevEn.toLowerCase());
    final matchesNe = u == nameNe || (abbrevNe.isNotEmpty && u == abbrevNe);
    if (matchesEn || matchesNe) {
      if (nepali) {
        return abbrevNe.isNotEmpty ? abbrevNe : nameNe;
      } else {
        return abbrevEn.isNotEmpty ? abbrevEn : nameEn;
      }
    }
  }
  return u;
}
