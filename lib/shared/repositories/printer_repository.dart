/// Saved printer configurations and the currently selected one.
library;

import 'package:sqflite/sqflite.dart';
import '../../core/db/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/printer.dart';

class PrinterRepository {
  final Future<Database> Function() _open;

  PrinterRepository({Future<Database> Function()? open})
      : _open = open ?? ((() => AppDatabase.open));

  Future<List<PrinterConfig>> list() async {
    final db = await _open();
    final rows = await db.query('printer_configurations', orderBy: 'id DESC');
    return rows.map(PrinterConfig.fromRow).toList();
  }

  Future<PrinterConfig?> selected() async {
    final db = await _open();
    final rows = await db.query(
      'printer_configurations',
      where: 'is_selected = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PrinterConfig.fromRow(rows.first);
  }

  Future<int> insert(PrinterConfig config) async {
    final db = await _open();
    if (config.isSelected) await _clearSelected(db);
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert(
      'printer_configurations',
      {...config.toRow(), 'created_at': now, 'updated_at': now},
    );
  }

  Future<void> update(PrinterConfig config) async {
    final db = await _open();
    if (config.isSelected) await _clearSelected(db);
    final count = await db.update(
      'printer_configurations',
      config.toRow(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
    if (count == 0) throw AppException(ErrorCode.notFound, 'printer ${config.id}');
  }

  /// Marks [id] the selected printer (single-selection invariant).
  Future<void> select(int id) async {
    final db = await _open();
    await _clearSelected(db);
    await db.update(
      'printer_configurations',
      {'is_selected': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> forget(int id) async {
    final db = await _open();
    await db.delete('printer_configurations', where: 'id = ?', whereArgs: [id]);
  }

  /// Upsert-or-select helper: saves attributes on [existingId] if > 0 else
  /// inserts; then selects it.
  ///
  /// A fresh insert first checks for an existing configuration with the same
  /// connection identity (USB: vendor+product id; LAN: host+port) and reuses
  /// that row instead of stacking duplicates of the same printer. Identity
  /// reuse updates connection attributes but preserves the stored display
  /// name, so re-tapping "Select" never clobbers a user-chosen printer name.
  Future<void> saveAndSelect({
    required int? existingId,
    required PrinterConfig config,
  }) async {
    final db = await _open();
    final now = DateTime.now().millisecondsSinceEpoch;
    var effectiveId = (existingId == null || existingId <= 0) ? 0 : existingId;
    Map<String, Object?>? reused;
    if (effectiveId <= 0) reused = await _findSameIdentity(db, config);
    if (reused != null) {
      effectiveId = (reused['id'] as num).toInt();
    }
    if (effectiveId <= 0) {
      final id = await db.insert(
        'printer_configurations',
        {...config.toRow(), 'is_selected': 1, 'created_at': now, 'updated_at': now},
      );
      await _clearSelected(db, exceptId: id);
    } else {
      final storedName = reused?['display_name'] as String? ?? '';
      // A user-renamed printer keeps its name on identity reuse; inserts and
      // explicit edits always carry the incoming (or new) name.
      final name = reused != null && storedName.isNotEmpty
          ? storedName
          : config.displayName;
      await db.update(
        'printer_configurations',
        {
          'display_name': name,
          'connection_type': config.connectionType.code,
          'host': config.host,
          'port': config.port,
          'usb_vendor_id': config.usbVendorId,
          'usb_product_id': config.usbProductId,
          'usb_device_name': config.usbDeviceName,
          'paper_width_mm': config.paperWidthMm,
          'rendering_mode': config.renderingMode.code,
          'enable_cut': config.enableCut ? 1 : 0,
          'enable_beep': config.enableBeep ? 1 : 0,
          'enable_drawer': config.enableDrawer ? 1 : 0,
          'is_selected': 1,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [effectiveId],
      );
      await _clearSelected(db, exceptId: effectiveId);
    }
  }

  /// Finds a saved configuration with the same connection identity as
  /// [config] (USB: vendor+product id + device path, where an empty path —
  /// the manual-add case — matches any stored path of the same unit model;
  /// LAN: host+port). Returns the matched row (id, display_name) or null.
  Future<Map<String, Object?>?> _findSameIdentity(
      Database db, PrinterConfig config) async {
    final where = StringBuffer('connection_type = ?');
    final args = <Object?>[config.connectionType.code];
    if (config.connectionType == ConnectionType.usb) {
      where.write(' AND usb_vendor_id = ? AND usb_product_id = ?');
      args.addAll([config.usbVendorId, config.usbProductId]);
      final path = config.usbDeviceName;
      where.write(' AND (usb_device_name = ? OR usb_device_name = "" OR ? = "")');
      args.addAll([path, path]);
    } else {
      where.write(' AND host = ? AND port = ?');
      args.addAll([config.host, config.port]);
    }
    final rows = await db.query(
      'printer_configurations',
      where: where.toString(),
      whereArgs: args,
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _clearSelected(Database db, {int? exceptId}) async {
    await db.update(
      'printer_configurations',
      {'is_selected': 0},
      where: exceptId == null ? 'is_selected = 1' : 'is_selected = 1 AND id <> ?',
      whereArgs: exceptId == null ? null : [exceptId],
    );
  }
}
