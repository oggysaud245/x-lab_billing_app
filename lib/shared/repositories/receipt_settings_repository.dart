/// Receipt design settings (row id = 1).
library;

import 'package:sqflite/sqflite.dart';
import '../../core/db/app_database.dart';
import '../models/receipt_settings.dart';

class ReceiptSettingsRepository {
  final Future<Database> Function() _open;

  ReceiptSettingsRepository({Future<Database> Function()? open})
      : _open = open ?? ((() => AppDatabase.open));

  Future<ReceiptSettings> load() async {
    final db = await _open();
    final rows = await db.query('receipt_settings', where: 'id = 1', limit: 1);
    return rows.isEmpty ? ReceiptSettings.defaults : ReceiptSettings.fromRow(rows.first);
  }

  static Future<ReceiptSettings> loadOn(Database db) async {
    final rows = await db.query('receipt_settings', where: 'id = 1', limit: 1);
    return rows.isEmpty ? ReceiptSettings.defaults : ReceiptSettings.fromRow(rows.first);
  }

  Future<void> save(ReceiptSettings s) async {
    final db = await _open();
    await db.insert(
      'receipt_settings',
      {...s.toRow(), 'id': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
