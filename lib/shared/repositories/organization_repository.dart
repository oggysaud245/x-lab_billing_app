/// Organization persistence: a single active row (first by id).
library;

import 'package:sqflite/sqflite.dart';
import '../../core/db/app_database.dart';
import '../models/organization.dart';

class OrganizationRepository {
  final Future<Database> Function() _open;

  OrganizationRepository({Future<Database> Function()? open})
      : _open = open ?? ((() => AppDatabase.open));

  Future<Organization> loadActive() async {
    final db = await _open();
    final rows = await db.query('organizations', orderBy: 'id ASC', limit: 1);
    return rows.isEmpty ? Organization.empty : Organization.fromRow(rows.first);
  }

  static Future<Organization> fromDb(Database db) async {
    final rows = await db.query('organizations', orderBy: 'id ASC', limit: 1);
    return rows.isEmpty ? Organization.empty : Organization.fromRow(rows.first);
  }

  /// Upsert: updates row 1 if it exists, otherwise inserts. Guarantees there
  /// is never more than one organization row.
  Future<Organization> upsert(Organization org) async {
    final db = await _open();
    return fromDbAndUpsert(db, org);
  }

  static Future<Organization> fromDbAndUpsert(Database db, Organization org) async {
    final first = await db.query('organizations', orderBy: 'id ASC', limit: 1);
    final row = org.toRow();
    if (first.isEmpty) {
      final id = await db.insert('organizations', row);
      final inserted = await db.query(
        'organizations',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return inserted.isEmpty ? org : Organization.fromRow(inserted.first);
    }
    final existingId = first.first['id'] as int;
    await db.delete('organizations', where: 'id <> ?', whereArgs: [existingId]);
    final updated = {
      'id': existingId,
      ...row,
      'created_at': first.first['created_at'],
    };
    await db.update('organizations', updated, where: 'id = ?', whereArgs: [existingId]);
    final after = await db.query(
      'organizations',
      where: 'id = ?',
      whereArgs: [existingId],
      limit: 1,
    );
    return after.isEmpty ? org : Organization.fromRow(after.first);
  }
}
