/// Units repository: seeded standard units + user-defined custom units.
library;

import 'package:sqflite/sqflite.dart';
import '../../core/db/app_database.dart';
import '../models/unit.dart';

class UnitRepository {
  final Future<Database> Function() _open;

  UnitRepository({Future<Database> Function()? open})
      : _open = open ?? ((() => AppDatabase.open));

  Future<List<Unit>> list({bool customOnly = false}) async {
    final db = await _open();
    final rows = await db.query(
      'units',
      orderBy: 'is_custom ASC, id ASC',
      where: customOnly ? 'is_custom = 1' : null,
    );
    return rows.map(Unit.fromRow).toList();
  }

  Future<Unit>? byIdFuture(int id) async => byId(id);

  Future<Unit> byId(int id) async {
    final db = await _open();
    final rows = await db.query('units', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      return Unit(
        id: id,
        nameEn: '',
        nameNe: '',
        abbrevEn: '',
        abbrevNe: '',
        isCustom: true,
      );
    }
    return Unit.fromRow(rows.first);
  }

  static Future<Map<int, Unit>> mapFor(Database db) async {
    final rows = await db.query('units');
    return {for (final r in rows) r['id'] as int: Unit.fromRow(r)};
  }

  /// Adds a custom unit if it doesn't already exist; returns the resulting
  /// unit (existing match has priority to prevent dupes).
  Future<Unit> addCustom({
    required String nameEn,
    required String nameNe,
    required String abbrevEn,
    required String abbrevNe,
  }) async {
    final db = await _open();
    final rows = await db.query('units');
    final candidates = rows.map(Unit.fromRow).where((u) => u.isCustom || true).toList();
    for (final u in candidates) {
      final sameNames = _eq(nameEn.trim(), u.nameEn) && _eq(nameNe.trim(), u.nameNe);
      final sameAbbrs =
          _eq(abbrevEn.trim(), u.abbrevEn) && _eq(abbrevNe.trim(), u.abbrevNe);
      final enMatch = _eq(nameEn.trim(), u.nameEn) && nameEn.trim().isNotEmpty;
      final neMatch = _eq(nameNe.trim(), u.nameNe) && nameNe.trim().isNotEmpty;
      if (sameNames || sameAbbrs || enMatch || neMatch) {
        return u;
      }
    }
    final id = await db.insert('units', {
      'name_en': nameEn.trim(),
      'name_ne': nameNe.trim(),
      'abbrev_en': abbrevEn.trim(),
      'abbrev_ne': abbrevNe.trim(),
      'is_custom': 1,
    });
    return Unit(
      id: id,
      nameEn: nameEn.trim(),
      nameNe: nameNe.trim(),
      abbrevEn: abbrevEn.trim(),
      abbrevNe: abbrevNe.trim(),
      isCustom: true,
    );
  }

  /// Counts how many products reference [unitId].
  Future<int> countProductsUsingUnit(int unitId) async {
    final db = await _open();
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE unit_id = ?',
      [unitId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Updates an existing custom unit's bilingual names and abbreviations.
  /// Standard system units (is_custom = 0) cannot be edited.
  Future<void> update(Unit unit) async {
    final db = await _open();
    await db.update(
      'units',
      {
        'name_en': unit.nameEn.trim(),
        'name_ne': unit.nameNe.trim(),
        'abbrev_en': unit.abbrevEn.trim(),
        'abbrev_ne': unit.abbrevNe.trim(),
      },
      where: 'id = ? AND is_custom = 1',
      whereArgs: [unit.id],
    );
  }

  /// Deletes a custom unit if it is not a system standard unit.
  Future<void> delete(int id) async {
    final db = await _open();
    await db.delete(
      'units',
      where: 'id = ? AND is_custom = 1',
      whereArgs: [id],
    );
  }
}

bool _eq(String a, String b) {
  final x = a.trim().toLowerCase();
  final y = b.trim().toLowerCase();
  return x.isNotEmpty && x == y;
}
