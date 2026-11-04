/// Product model. Both English and Nepali names/units are stored
/// independently; when one is missing we fall back to the other
/// rather than printing an empty name.
library;

import '../../core/formatting/money.dart';
import 'unit.dart';

class Product {
  final int id;
  final String nameEn;
  final String nameNe;
  final String sku;
  final String descriptionEn;
  final String descriptionNe;
  final int ratePaisa;
  final int unitId;
  final Unit? unit;
  final String category;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  const Product({
    required this.id,
    required this.nameEn,
    required this.nameNe,
    required this.sku,
    required this.descriptionEn,
    required this.descriptionNe,
    required this.ratePaisa,
    required this.unitId,
    this.unit,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromRow(Map<String, Object?> row, {Unit? unit}) => Product(
        id: row['id'] as int,
        nameEn: row['name_en'] as String? ?? '',
        nameNe: row['name_ne'] as String? ?? '',
        sku: row['sku'] as String? ?? '',
        descriptionEn: row['description_en'] as String? ?? '',
        descriptionNe: row['description_ne'] as String? ?? '',
        ratePaisa: row['rate_paisa'] as int? ?? 0,
        unitId: row['unit_id'] as int? ?? 0,
        category: row['category'] as String? ?? '',
        isActive: (row['is_active'] as int? ?? 1) != 0,
        createdAt: row['created_at'] as int? ?? 0,
        updatedAt: row['updated_at'] as int? ?? 0,
      );

  Map<String, Object?> toRow({bool withTimestamps = true}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      if (id > 0) 'id': id,
      'name_en': nameEn.trim(),
      'name_ne': nameNe.trim(),
      'sku': sku.trim(),
      'description_en': descriptionEn.trim(),
      'description_ne': descriptionNe.trim(),
      'rate_paisa': ratePaisa,
      'unit_id': unitId,
      'category': category.trim(),
      'is_active': isActive ? 1 : 0,
      if (withTimestamps) ...{
        'created_at': createdAt > 0 ? createdAt : now,
        'updated_at': now,
      },
    };
  }

  /// Display name preferring [nepali] when available, with a defined
  /// non-empty fallback to the other language.
  String displayName({bool nepali = false}) {
    final primary = nepali ? nameNe : nameEn;
    if (primary.trim().isNotEmpty) return primary;
    final secondary = nepali ? nameEn : nameNe;
    if (secondary.trim().isNotEmpty) return secondary;
    if (sku.trim().isNotEmpty) return sku;
    return '—';
  }

  String unitDisplay({bool nepali = false}) {
    final u = unit;
    if (u == null) return '';
    final primary = nepali ? u.displayNe : u.displayEn;
    if (primary.trim().isNotEmpty) return primary;
    return nepali ? u.displayEn : u.displayNe;
  }

  bool matches(String query) {
    final q = normalizeDigits(query.trim().toLowerCase());
    if (q.isEmpty) return true;
    return nameEn.toLowerCase().contains(q) ||
        nameNe.contains(query.trim()) ||
        nameNe.contains(q) ||
        sku.toLowerCase().contains(q);
  }

  Product copyWith({
    String? nameEn,
    String? nameNe,
    String? sku,
    String? descriptionEn,
    String? descriptionNe,
    int? ratePaisa,
    int? unitId,
    Unit? unit,
    String? category,
    bool? isActive,
  }) =>
      Product(
        id: id,
        nameEn: nameEn ?? this.nameEn,
        nameNe: nameNe ?? this.nameNe,
        sku: sku ?? this.sku,
        descriptionEn: descriptionEn ?? this.descriptionEn,
        descriptionNe: descriptionNe ?? this.descriptionNe,
        ratePaisa: ratePaisa ?? this.ratePaisa,
        unitId: unitId ?? this.unitId,
        unit: unit ?? this.unit,
        category: category ?? this.category,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
