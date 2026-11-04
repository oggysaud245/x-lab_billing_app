/// SQLite access layer (sqflite).
///
/// Schema v1 contains: organizations, units, products, invoices,
/// invoice_items, printer_configurations, receipt_settings, app_settings
/// (key/value) and print_jobs.
///
/// Monetary values are stored as integer paisa; quantities as integer
/// thousandths; percentages as integer hundredths. See
/// `core/formatting/money.dart`.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../errors/app_exception.dart';

const int dbVersion = 1;

class AppDatabase {
  AppDatabase._();
  static Database? _db;

  /// Returns the open database, opening it lazily.
  static Future<Database> get open async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    final dir = await defaultDirectory;
    final path = p.join(dir, 'xlab_billing.db');
    _db = await _openAt(path);
    return _db!;
  }

  static Future<String> _defaultDir() async => getDatabasesPath();

  static Future<String> get defaultDirectory => _defaultDir();

  /// Opens the database file at [path] (used by restore flows and tests).
  static Future<Database> openAt(String path) async {
    _db = await _openAt(path);
    return _db!;
  }

  /// Closes the connection (used before file copies and in tests).
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Database? get current => _db;

  /// Replaces the database file at [targetPath] with [sourcePath].
  static Future<void> replaceDatabaseFile(String sourcePath, String targetPath) async {
    await close();
    final src = File(sourcePath);
    if (!src.existsSync()) {
      throw AppException(ErrorCode.restoreFailure, 'missing $sourcePath');
    }
    await File(targetPath).writeAsBytes(src.readAsBytesSync(), flush: true);
    await openAt(targetPath);
  }

  static Future<Database> _openAt(String path) async {
    try {
      final db = await openDatabase(
        path,
        version: dbVersion,
        onConfigure: (d) async {
          await d.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (d, v) => createSchema(d),
        onUpgrade: (d, oldV, newV) async {
          // Future migrations go here (oldV -> newV), preserving data.
        },
      );
      return db;
    } on DatabaseException {
      rethrow;
    } catch (e, st) {
      throw AppException(ErrorCode.dbFailure, 'open failed: $e\n$st');
    }
  }
}

/// Creates all tables/indexes and seeds defaults. Exposed for tests so the
/// in-memory ffi database mirrors production exactly.
Future<void> createSchema(DatabaseExecutor d) async {
  for (final stmt in schemaStatements) {
    await d.execute(stmt);
  }
  await seedDefaults(d);
}

Future<void> seedDefaults(DatabaseExecutor db) async {
  final batch = db.batch();
  for (final u in defaultUnits) {
    batch.insert('units', {
      'name_en': u.$1,
      'name_ne': u.$2,
      'abbrev_en': u.$3,
      'abbrev_ne': u.$4,
      'is_custom': 0,
    });
  }
  batch.insert('receipt_settings', {'id': 1});
  batch.insert('app_settings', {'key': 'invoice_next', 'value': '1'});
  await batch.commit(noResult: true);
}

const List<String> schemaStatements = [
  'CREATE TABLE organizations ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name_en TEXT NOT NULL DEFAULT "", '
      'name_ne TEXT NOT NULL DEFAULT "", '
      'address_en TEXT NOT NULL DEFAULT "", '
      'address_ne TEXT NOT NULL DEFAULT "", '
      'phone TEXT NOT NULL DEFAULT "", '
      'alternative_phone TEXT NOT NULL DEFAULT "", '
      'email TEXT NOT NULL DEFAULT "", '
      'pan_number TEXT NOT NULL DEFAULT "", '
      'vat_number TEXT NOT NULL DEFAULT "", '
      'registration_number TEXT NOT NULL DEFAULT "", '
      'website TEXT NOT NULL DEFAULT "", '
      'logo_path TEXT NOT NULL DEFAULT "", '
      'custom_info_en TEXT NOT NULL DEFAULT "", '
      'custom_info_ne TEXT NOT NULL DEFAULT "", '
      'created_at INTEGER NOT NULL DEFAULT 0, '
      'updated_at INTEGER NOT NULL DEFAULT 0)',

  'CREATE TABLE units ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name_en TEXT NOT NULL, '
      'name_ne TEXT NOT NULL, '
      'abbrev_en TEXT NOT NULL, '
      'abbrev_ne TEXT NOT NULL, '
      'is_custom INTEGER NOT NULL DEFAULT 0, '
      'UNIQUE(name_en, name_ne))',

  'CREATE TABLE products ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name_en TEXT NOT NULL DEFAULT "", '
      'name_ne TEXT NOT NULL DEFAULT "", '
      'sku TEXT NOT NULL DEFAULT "", '
      'description_en TEXT NOT NULL DEFAULT "", '
      'description_ne TEXT NOT NULL DEFAULT "", '
      'rate_paisa INTEGER NOT NULL DEFAULT 0, '
      'unit_id INTEGER NOT NULL REFERENCES units(id), '
      'category TEXT NOT NULL DEFAULT "", '
      'is_active INTEGER NOT NULL DEFAULT 1, '
      'created_at INTEGER NOT NULL DEFAULT 0, '
      'updated_at INTEGER NOT NULL DEFAULT 0)',
  'CREATE INDEX idx_products_active ON products(is_active)',
  'CREATE INDEX idx_products_category ON products(category)',

  'CREATE TABLE invoices ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'invoice_number TEXT NOT NULL UNIQUE, '
      'invoice_number_seq INTEGER NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'org_snapshot TEXT NOT NULL, '
      'receipt_snapshot TEXT NOT NULL, '
      'app_settings_snapshot TEXT NOT NULL, '
      'invoice_language TEXT NOT NULL, '
      'date_system TEXT NOT NULL, '
      'date_style TEXT NOT NULL, '
      'numeral_format TEXT NOT NULL, '
      'customer_json TEXT, '
      'discount_type TEXT NOT NULL DEFAULT "none", '
      'discount_value INTEGER NOT NULL DEFAULT 0, '
      'discount_amount INTEGER NOT NULL DEFAULT 0, '
      'tax_rate INTEGER NOT NULL DEFAULT 0, '
      'tax_amount INTEGER NOT NULL DEFAULT 0, '
      'other_charges INTEGER NOT NULL DEFAULT 0, '
      'other_charges_note TEXT NOT NULL DEFAULT "", '
      'subtotal INTEGER NOT NULL, '
      'grand_total INTEGER NOT NULL, '
      'amount_paid INTEGER NOT NULL DEFAULT 0, '
      'balance_due INTEGER NOT NULL DEFAULT 0, '
      'payment_method TEXT, '
      'notes TEXT NOT NULL DEFAULT "", '
      'status TEXT NOT NULL DEFAULT "finalized", '
      'status_note TEXT NOT NULL DEFAULT "", '
      'updated_at INTEGER NOT NULL DEFAULT 0)',
  'CREATE INDEX idx_invoices_created ON invoices(created_at)',
  'CREATE INDEX idx_invoices_status ON invoices(status)',

  'CREATE TABLE invoice_items ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE, '
      'product_id INTEGER, '
      'name_snapshot_en TEXT NOT NULL, '
      'name_snapshot_ne TEXT NOT NULL, '
      'sku_snapshot TEXT NOT NULL DEFAULT "", '
      'unit_snapshot_en TEXT NOT NULL, '
      'unit_snapshot_ne TEXT NOT NULL, '
      'quantity_milli INTEGER NOT NULL, '
      'rate_paisa INTEGER NOT NULL, '
      'line_total_paisa INTEGER NOT NULL, '
      'position INTEGER NOT NULL DEFAULT 0)',
  'CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id)',

  'CREATE TABLE printer_configurations ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'display_name TEXT NOT NULL, '
      'connection_type TEXT NOT NULL, '
      'host TEXT NOT NULL DEFAULT "", '
      'port INTEGER NOT NULL DEFAULT 9100, '
      'usb_vendor_id INTEGER, '
      'usb_product_id INTEGER, '
      'usb_device_name TEXT NOT NULL DEFAULT "", '
      'paper_width_mm INTEGER NOT NULL DEFAULT 58, '
      'rendering_mode TEXT NOT NULL DEFAULT "auto", '
      'enable_cut INTEGER NOT NULL DEFAULT 1, '
      'enable_beep INTEGER NOT NULL DEFAULT 0, '
      'enable_drawer INTEGER NOT NULL DEFAULT 0, '
      'is_selected INTEGER NOT NULL DEFAULT 0, '
      'created_at INTEGER NOT NULL DEFAULT 0, '
      'updated_at INTEGER NOT NULL DEFAULT 0)',

  'CREATE TABLE receipt_settings ('
      'id INTEGER NOT NULL UNIQUE CHECK (id = 1), '
      'logo_path TEXT NOT NULL DEFAULT "", '
      'header_align TEXT NOT NULL DEFAULT "center", '
      'text_size TEXT NOT NULL DEFAULT "normal", '
      'welcome_en TEXT NOT NULL DEFAULT "", '
      'welcome_ne TEXT NOT NULL DEFAULT "", '
      'thank_en TEXT NOT NULL DEFAULT "", '
      'thank_ne TEXT NOT NULL DEFAULT "", '
      'policy_en TEXT NOT NULL DEFAULT "", '
      'policy_ne TEXT NOT NULL DEFAULT "", '
      'terms_en TEXT NOT NULL DEFAULT "", '
      'terms_ne TEXT NOT NULL DEFAULT "", '
      'promo_en TEXT NOT NULL DEFAULT "", '
      'promo_ne TEXT NOT NULL DEFAULT "", '
      'extra_en TEXT NOT NULL DEFAULT "", '
      'extra_ne TEXT NOT NULL DEFAULT "", '
      'show_logo INTEGER NOT NULL DEFAULT 0, '
      'show_address INTEGER NOT NULL DEFAULT 1, '
      'show_phone INTEGER NOT NULL DEFAULT 1, '
      'show_email INTEGER NOT NULL DEFAULT 0, '
      'show_website INTEGER NOT NULL DEFAULT 0, '
      'show_pan_vat INTEGER NOT NULL DEFAULT 1, '
      'show_customer INTEGER NOT NULL DEFAULT 1, '
      'show_payment INTEGER NOT NULL DEFAULT 1)',

  'CREATE TABLE app_settings ('
      'key TEXT PRIMARY KEY, '
      'value TEXT NOT NULL)',

  'CREATE TABLE print_jobs ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE, '
      'attempted_at INTEGER NOT NULL, '
      'status TEXT NOT NULL, '
      'connection_type TEXT, '
      'error_message TEXT NOT NULL DEFAULT "")',
  'CREATE INDEX idx_print_jobs_invoice ON print_jobs(invoice_id)',
];

const List<(String, String, String, String)> defaultUnits = [
  ('Piece', 'पिस', 'pcs', 'पिस'),
  ('Kilogram', 'किलोग्राम', 'kg', 'कि.गा.'),
  ('Gram', 'ग्राम', 'g', 'ग्रा.'),
  ('Liter', 'लिटर', 'L', 'लि.'),
  ('Milliliter', 'मिलिलिटर', 'mL', 'मि.लि.'),
  ('Meter', 'मिटर', 'm', 'मी.'),
  ('Centimeter', 'सेन्टिमिटर', 'cm', 'से.मी.'),
  ('Box', 'बक्सा', 'box', 'बक्सा'),
  ('Packet', 'प्याकेट', 'pkt', 'प्याकेट'),
  ('Dozen', 'दर्जन', 'dz', 'दर्जन'),
  ('Plate', 'प्लेट', 'plate', 'प्लेट'),
  ('Serving', 'सर्भिङ', 'serving', 'सर्भिङ'),
];

@visibleForTesting
final List<String> schemaForTests = schemaStatements;
