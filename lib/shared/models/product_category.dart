/// Product category with bilingual English/Nepali names.
library;

class ProductCategory implements Comparable<ProductCategory> {
  final String nameEn;
  final String nameNe;

  const ProductCategory({
    required this.nameEn,
    required this.nameNe,
  });

  /// The primary identifier used in product rows and queries.
  /// Falls back to nameNe if nameEn is empty.
  String get key => nameEn.isNotEmpty ? nameEn : nameNe;

  /// Returns localized display name based on [nepali] setting.
  String displayName({bool nepali = false}) {
    final primary = nepali ? nameNe : nameEn;
    final secondary = nepali ? nameEn : nameNe;
    return primary.isNotEmpty ? primary : secondary;
  }

  ProductCategory copyWith({
    String? nameEn,
    String? nameNe,
  }) =>
      ProductCategory(
        nameEn: nameEn ?? this.nameEn,
        nameNe: nameNe ?? this.nameNe,
      );

  String toLowerCase() => key.toLowerCase();
  String toUpperCase() => key.toUpperCase();

  Map<String, dynamic> toJson() => {
        'name_en': nameEn,
        'name_ne': nameNe,
      };

  factory ProductCategory.fromJson(dynamic json) {
    if (json is ProductCategory) return json;
    if (json is String) {
      final s = json.trim();
      return ProductCategory(nameEn: s, nameNe: '');
    }
    if (json is Map<String, dynamic>) {
      return ProductCategory(
        nameEn: (json['name_en'] as String? ?? '').trim(),
        nameNe: (json['name_ne'] as String? ?? '').trim(),
      );
    }
    return const ProductCategory(nameEn: '', nameNe: '');
  }

  bool matches(String identifier) {
    final needle = identifier.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return nameEn.trim().toLowerCase() == needle ||
        nameNe.trim().toLowerCase() == needle;
  }

  @override
  int compareTo(ProductCategory other) =>
      key.toLowerCase().compareTo(other.key.toLowerCase());

  @override
  String toString() => key;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is String) {
      return matches(other) || key.toLowerCase() == other.trim().toLowerCase();
    }
    return other is ProductCategory &&
        runtimeType == other.runtimeType &&
        nameEn.trim().toLowerCase() == other.nameEn.trim().toLowerCase() &&
        nameNe.trim().toLowerCase() == other.nameNe.trim().toLowerCase();
  }

  @override
  int get hashCode =>
      nameEn.trim().toLowerCase().hashCode ^
      nameNe.trim().toLowerCase().hashCode;
}
