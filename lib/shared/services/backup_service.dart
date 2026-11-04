/// Database backup/restore and CSV export. Backups are copies of the SQLite
/// database file into a folder the app owns on the device's external
/// storage (no special permissions needed on Android).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/db/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/invoice.dart';

class BackupService {
  const BackupService();

  static const backupPrefix = 'xlab_billing_backup_';

  Future<Directory> backupDirectory() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final d = Directory(p.join(ext.path, 'backups'));
        await d.create(recursive: true);
        return d;
      }
    } catch (_) {
      // fall through to internal dir
    }
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, 'backups'));
    await d.create(recursive: true);
    return d;
  }

  Future<List<File>> listBackups() async {
    try {
      final dir = await backupDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith(backupPrefix) && f.path.endsWith('.db'))
          .toList()
        ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// Flush WAL then copy the database file.
  Future<File> createBackup() async {
    final db = await AppDatabase.open;
    try {
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {
      // Older/newer clients may not support it; plain copy still works.
    }
    final dir = await backupDirectory();
    final stamp = DateTime.now();
    final name = '$backupPrefix'
        '${stamp.year}${_two(stamp.month)}${_two(stamp.day)}_'
        '${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}.db';
    final source = File(p.join(await AppDatabase.defaultDirectory, 'xlab_billing.db'));
    await AppDatabase.close();
    final copy = File(p.join(dir.path, name));
    await copy.writeAsBytes(source.readAsBytesSync(), flush: true);
    await AppDatabase.openAt(source.path);
    return copy;
  }

  /// Restores [backup] over the live database and reopens it.
  Future<void> restoreBackup(String backupPath) async {
    try {
      final dir = await AppDatabase.defaultDirectory;
      final target = p.join(dir, 'xlab_billing.db');
      await AppDatabase.replaceDatabaseFile(backupPath, target);
    } catch (e) {
      throw AppException(ErrorCode.restoreFailure, e.toString());
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Exports finalized invoices + items as CSV (UTF-8, Excel-compatible
  /// BOM). Returns the written file.
  Future<File> exportInvoicesCsv(List<Invoice> invoices) async {
    final dir = await backupDirectory();
    final stamp = DateTime.now();
    final name = 'xlab_invoices_${stamp.year}${_two(stamp.month)}${_two(stamp.day)}'
        '_${_two(stamp.hour)}${_two(stamp.minute)}.csv';
    final f = File(p.join(dir.path, name));
    final sb = StringBuffer();
    sb.writeln('"invoice_number","date","customer","items","subtotal","discount","tax","other_charges","grand_total","paid","due","payment_method","status"');
    for (final inv in invoices) {
      final customer = inv.customer?.name ?? '';
      final itemsText = inv.items
          .map((i) => '${i.nameSnapshotEn}/${i.nameSnapshotNe} x${i.quantityMilli / 1000} = ${(i.lineTotalPaisa / 100).toStringAsFixed(2)}')
          .join('; ');
      String csv(String v) => '"${v.replaceAll('"', '""')}"';
      sb.writeln([
        csv(inv.invoiceNumber),
        csv(DateTime.fromMillisecondsSinceEpoch(inv.createdAt).toIso8601String()),
        csv(customer),
        csv(itemsText),
        (inv.totals.subtotalPaisa / 100).toStringAsFixed(2),
        (inv.totals.discountAmount / 100).toStringAsFixed(2),
        (inv.totals.taxAmount / 100).toStringAsFixed(2),
        (inv.totals.otherCharges / 100).toStringAsFixed(2),
        (inv.totals.grandTotal / 100).toStringAsFixed(2),
        (inv.totals.amountPaid / 100).toStringAsFixed(2),
        (inv.totals.balanceDue / 100).toStringAsFixed(2),
        csv(inv.paymentMethod.code),
        csv(inv.status.code),
      ].join(','));
    }
    final bytes = utf8.encode('\uFEFF${sb.toString()}');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }
}
