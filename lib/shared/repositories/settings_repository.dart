/// Loads and persists app settings from the key/value app_settings table.
library;

import 'package:sqflite/sqflite.dart';
import '../../core/db/app_database.dart';
import '../models/app_settings.dart';
import '../models/billing_profile.dart';
import '../models/receipt_profile.dart';

class SettingsRepository {
  final Future<Database> Function() _open;

  SettingsRepository({Future<Database> Function()? open})
      : _open = open ?? ((() => AppDatabase.open));

  Future<AppSettings> load() async {
    final db = await _open();
    final rows = await db.query('app_settings');
    final kv = <String, String>{};
    for (final r in rows) {
      kv[r['key'] as String] = r['value'] as String? ?? '';
    }
    return AppSettings.fromKeyValue(kv);
  }

  Future<void> save(Map<String, String> kv) async {
    final db = await _open();
    final batch = db.batch();
    for (final e in kv.entries) {
      batch.insert(
        'app_settings',
        {'key': e.key, 'value': e.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Atomically reserves the next invoice sequence. Returns the reserved
  /// sequence number. Called inside the finalize transaction.
  Future<int> reserveInvoiceNumber(Transaction txn) async {
    final rows = await txn.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['invoice_next'],
      limit: 1,
    );
    final current = int.tryParse(rows.isEmpty ? '1' : (rows.first['value'] as String? ?? '1')) ?? 1;
    await txn.update(
      'app_settings',
      {'value': (current + 1).toString()},
      where: 'key = ?',
      whereArgs: ['invoice_next'],
    );
    return current;
  }

  /// Reads the next number without consuming it (for previews).
  Future<int> peekInvoiceNumber() async {
    final db = await _open();
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['invoice_next'],
      limit: 1,
    );
    return int.tryParse(rows.isEmpty ? '1' : (rows.first['value'] as String? ?? '1')) ?? 1;
  }

  Future<void> setInvoiceNext(int next) => save({'invoice_next': next.toString()});

  Future<(List<ReceiptProfile> profiles, String? activeId)> loadProfiles() async {
    final db = await _open();
    final rows = await db.query(
      'app_settings',
      where: "key IN ('receipt_profiles_json', 'active_receipt_profile_id')",
    );
    String? rawJson;
    String? activeId;
    for (final r in rows) {
      final k = r['key'] as String?;
      final v = r['value'] as String?;
      if (k == 'receipt_profiles_json') rawJson = v;
      if (k == 'active_receipt_profile_id') activeId = v;
    }
    return (ReceiptProfile.decodeList(rawJson), activeId);
  }

  Future<void> saveProfiles(List<ReceiptProfile> profiles, String activeId) =>
      save({
        'receipt_profiles_json': ReceiptProfile.encodeList(profiles),
        'active_receipt_profile_id': activeId,
      });

  Future<(List<BillingProfile> profiles, String? activeId)>
      loadBillingProfiles() async {
    final db = await _open();
    final rows = await db.query(
      'app_settings',
      where: "key IN ('billing_profiles_json', 'active_billing_profile_id')",
    );
    String? rawJson;
    String? activeId;
    for (final r in rows) {
      final k = r['key'] as String?;
      final v = r['value'] as String?;
      if (k == 'billing_profiles_json') rawJson = v;
      if (k == 'active_billing_profile_id') activeId = v;
    }
    return (BillingProfile.decodeList(rawJson), activeId);
  }

  Future<void> saveBillingProfiles(
    List<BillingProfile> profiles,
    String activeId,
  ) =>
      save({
        'billing_profiles_json': BillingProfile.encodeList(profiles),
        'active_billing_profile_id': activeId,
      });
}

// ConflictAlgorithm re-export shim (sqflite exports it via sqflite_common).
