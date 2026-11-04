/// Products repository with bilingual names, units, categories and sorting.
library;

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../../core/db/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/unit.dart';

enum ProductSort {
  name,
  nameAsc,
  nameDesc,
  rate,
  rateAsc,
  rateDesc,
  newest,
  oldest,
  id,
}

class ProductQuery {
  final String search;
  final String category; // '' = all
  final bool includeInactive;
  final ProductSort sort;

  const ProductQuery({
    this.search = '',
    this.category = '',
    this.includeInactive = false,
    this.sort = ProductSort.name,
  });
}

class ProductRepository {
  final Future<Database> Function() _open;

  ProductRepository({Future<Database> Function()? open})
      : _open = open ?? ((() => AppDatabase.open));

  /// Lists products joined with their units.
  Future<List<Product>> list(ProductQuery q) async {
    final db = await _open();
    return listOn(db, q);
  }

  static Future<List<Product>> listOn(Database db, ProductQuery q) async {
    final where = <String>[];
    final args = <Object?>[];
    if (!q.includeInactive) where.add('p.is_active = 1');
    if (q.category.isNotEmpty) {
      where.add('p.category = ?');
      args.add(q.category);
    }
    if (q.search.trim().isNotEmpty) {
      final needle = '%${q.search.trim()}%';
      where.add('(p.name_en LIKE ? OR p.name_ne LIKE ? OR p.sku LIKE ?)');
      args.addAll([needle, needle, needle]);
    }
    final orderBy = switch (q.sort) {
      ProductSort.name ||
      ProductSort.nameAsc =>
        'p.name_en COLLATE NOCASE ASC, p.name_ne COLLATE NOCASE ASC',
      ProductSort.nameDesc =>
        'p.name_en COLLATE NOCASE DESC, p.name_ne COLLATE NOCASE DESC',
      ProductSort.rate ||
      ProductSort.rateAsc =>
        'p.rate_paisa ASC, p.name_en COLLATE NOCASE ASC',
      ProductSort.rateDesc =>
        'p.rate_paisa DESC, p.name_en COLLATE NOCASE ASC',
      ProductSort.newest => 'p.created_at DESC, p.id DESC',
      ProductSort.oldest => 'p.created_at ASC, p.id ASC',
      ProductSort.id => 'p.id ASC',
    };
    final rows = await db.rawQuery(
      'SELECT p.*, u.name_en AS u_name_en, u.name_ne AS u_name_ne, '
      'u.abbrev_en AS u_abbrev_en, u.abbrev_ne AS u_abbrev_ne, '
      'u.is_custom AS u_is_custom FROM products p '
      'LEFT JOIN units u ON u.id = p.unit_id '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
      'ORDER BY $orderBy',
      args,
    );
    return rows.map((r) {
      final unit = Unit(
        id: r['unit_id'] as int? ?? 0,
        nameEn: r['u_name_en'] as String? ?? '',
        nameNe: r['u_name_ne'] as String? ?? '',
        abbrevEn: r['u_abbrev_en'] as String? ?? '',
        abbrevNe: r['u_abbrev_ne'] as String? ?? '',
        isCustom: (r['u_is_custom'] as int? ?? 0) != 0,
      );
      final prod = Product.fromRow(r);
      return Product(
        id: prod.id,
        nameEn: prod.nameEn,
        nameNe: prod.nameNe,
        sku: prod.sku,
        descriptionEn: prod.descriptionEn,
        descriptionNe: prod.descriptionNe,
        ratePaisa: prod.ratePaisa,
        unitId: prod.unitId,
        unit: unit,
        category: prod.category,
        isActive: prod.isActive,
        createdAt: prod.createdAt,
        updatedAt: prod.updatedAt,
      );
    }).toList();
  }

  Future<Product?> byId(int id) async {
    final db = await _open();
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final prod = Product.fromRow(rows.first);
    final unitRows = await db.query('units', where: 'id = ?', whereArgs: [prod.unitId], limit: 1);
    return prod.copyWith(
      unit: unitRows.isEmpty
          ? null
          : (rows.isEmpty ? null : ProductUnitMapper.unitFrom(unitRows.first)),
    );
  }

  Future<int> insert(Product product) async {
    final db = await _open();
    try {
      return await db.insert('products', product.toRow());
    } catch (e) {
      throw AppException(ErrorCode.dbFailure, 'insert product: $e');
    }
  }

  Future<void> update(Product product) async {
    final db = await _open();
    final count = await db.update(
      'products',
      product.toRow(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    if (count == 0) throw AppException(ErrorCode.notFound, 'product ${product.id}');
  }

  Future<void> setActive(int id, bool active) async {
    final db = await _open();
    await db.update(
      'products',
      {
        'is_active': active ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProductCategory>> categories() async {
    final db = await _open();
    final settingRows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['product_categories_json'],
      limit: 1,
    );
    final map = <String, ProductCategory>{};
    if (settingRows.isNotEmpty) {
      final raw = settingRows.first['value'] as String? ?? '';
      if (raw.isNotEmpty) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          for (final item in list) {
            final cat = ProductCategory.fromJson(item);
            if (cat.nameEn.isNotEmpty || cat.nameNe.isNotEmpty) {
              map[cat.key.toLowerCase()] = cat;
            }
          }
        } catch (_) {}
      }
    }
    final rows = await db.rawQuery(
      "SELECT DISTINCT category FROM products WHERE TRIM(category) <> ''",
    );
    for (final r in rows) {
      final s = (r['category'] as String? ?? '').trim();
      if (s.isNotEmpty) {
        final already = map.values.any((c) => c.matches(s));
        if (!already) {
          map[s.toLowerCase()] = ProductCategory(nameEn: s, nameNe: '');
        }
      }
    }
    final sorted = map.values.toList()..sort();
    return sorted;
  }

  Future<void> addCategory(dynamic category) async {
    final ProductCategory cat;
    if (category is ProductCategory) {
      cat = category;
    } else if (category is String) {
      cat = ProductCategory(nameEn: category.trim(), nameNe: '');
    } else {
      return;
    }
    if (cat.nameEn.isEmpty && cat.nameNe.isEmpty) return;

    final db = await _open();
    final cats = await categories();
    final exists = cats.any((c) =>
        c.key.toLowerCase() == cat.key.toLowerCase() ||
        (cat.nameEn.isNotEmpty &&
            c.nameEn.toLowerCase() == cat.nameEn.toLowerCase()) ||
        (cat.nameNe.isNotEmpty &&
            c.nameNe.toLowerCase() == cat.nameNe.toLowerCase()));
    if (!exists) {
      cats.add(cat);
      cats.sort();
      await db.insert(
        'app_settings',
        {
          'key': 'product_categories_json',
          'value': jsonEncode(cats.map((c) => c.toJson()).toList()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Counts how many products belong to [category] (matches by key, nameEn, or nameNe).
  Future<int> countProductsInCategory(dynamic category) async {
    final Set<String> identifiers;
    if (category is ProductCategory) {
      identifiers = {
        category.key,
        if (category.nameEn.isNotEmpty) category.nameEn,
        if (category.nameNe.isNotEmpty) category.nameNe,
      };
    } else if (category is String) {
      final trimmed = category.trim();
      if (trimmed.isEmpty) return 0;
      identifiers = {trimmed};
      final allCats = await categories();
      for (final c in allCats) {
        if (c.matches(trimmed) || c.key.toLowerCase() == trimmed.toLowerCase()) {
          identifiers.add(c.key);
          if (c.nameEn.isNotEmpty) identifiers.add(c.nameEn);
          if (c.nameNe.isNotEmpty) identifiers.add(c.nameNe);
        }
      }
    } else {
      return 0;
    }

    final db = await _open();
    final placeholders = List.filled(identifiers.length, '?').join(', ');
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE category IN ($placeholders)',
      identifiers.toList(),
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Renames or updates an existing category across saved settings and existing products.
  Future<void> updateCategory(dynamic oldCat, dynamic newCat) async {
    final ProductCategory oldCategory = oldCat is ProductCategory
        ? oldCat
        : ProductCategory(nameEn: oldCat.toString().trim(), nameNe: '');
    final ProductCategory newCategory = newCat is ProductCategory
        ? newCat
        : ProductCategory(nameEn: newCat.toString().trim(), nameNe: '');

    if (oldCategory.nameEn.isEmpty && oldCategory.nameNe.isEmpty) return;
    if (newCategory.nameEn.isEmpty && newCategory.nameNe.isEmpty) return;
    if (oldCategory == newCategory) return;

    final db = await _open();
    final cats = await categories();

    final oldIdentifiers = <String>{
      if (oldCategory.key.isNotEmpty) oldCategory.key,
      if (oldCategory.nameEn.isNotEmpty) oldCategory.nameEn,
      if (oldCategory.nameNe.isNotEmpty) oldCategory.nameNe,
      if (oldCat is String && oldCat.trim().isNotEmpty) oldCat.trim(),
    };

    cats.removeWhere((c) =>
        c == oldCategory ||
        oldIdentifiers.any(
            (id) => c.matches(id) || c.key.toLowerCase() == id.toLowerCase()));

    cats.removeWhere((c) =>
        (newCategory.nameEn.isNotEmpty &&
            c.nameEn.toLowerCase() == newCategory.nameEn.toLowerCase()) ||
        (newCategory.nameNe.isNotEmpty &&
            c.nameNe.toLowerCase() == newCategory.nameNe.toLowerCase()));

    cats.add(newCategory);
    cats.sort();

    await db.insert(
      'app_settings',
      {
        'key': 'product_categories_json',
        'value': jsonEncode(cats.map((c) => c.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (oldIdentifiers.isNotEmpty) {
      final placeholders = List.filled(oldIdentifiers.length, '?').join(', ');
      await db.rawUpdate(
        'UPDATE products SET category = ? WHERE category IN ($placeholders)',
        [newCategory.key, ...oldIdentifiers],
      );
    }
  }

  /// Deletes a category from saved settings and unassigns it from products.
  Future<void> deleteCategory(dynamic category) async {
    final ProductCategory cat = category is ProductCategory
        ? category
        : ProductCategory(nameEn: category.toString().trim(), nameNe: '');

    if (cat.nameEn.isEmpty && cat.nameNe.isEmpty) return;

    final db = await _open();
    final cats = await categories();

    final identifiers = <String>{
      if (cat.key.isNotEmpty) cat.key,
      if (cat.nameEn.isNotEmpty) cat.nameEn,
      if (cat.nameNe.isNotEmpty) cat.nameNe,
      if (category is String && category.trim().isNotEmpty) category.trim(),
    };

    cats.removeWhere((c) =>
        c == cat ||
        identifiers.any(
            (id) => c.matches(id) || c.key.toLowerCase() == id.toLowerCase()));

    await db.insert(
      'app_settings',
      {
        'key': 'product_categories_json',
        'value': jsonEncode(cats.map((c) => c.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (identifiers.isNotEmpty) {
      final placeholders = List.filled(identifiers.length, '?').join(', ');
      await db.rawUpdate(
        'UPDATE products SET category = "" WHERE category IN ($placeholders)',
        identifiers.toList(),
      );
    }
  }
}

class ProductUnitMapper {
  static Unit unitFrom(Map<String, Object?> row) => Unit(
        id: row['id'] as int? ?? 0,
        nameEn: row['name_en'] as String? ?? '',
        nameNe: row['name_ne'] as String? ?? '',
        abbrevEn: row['abbrev_en'] as String? ?? '',
        abbrevNe: row['abbrev_ne'] as String? ?? '',
        isCustom: (row['is_custom'] as int? ?? 0) != 0,
      );
}
