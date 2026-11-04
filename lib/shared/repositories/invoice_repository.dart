/// Invoice persistence, including the transactional number reservation and
/// snapshot preservation that make finalized invoices immutable.
library;

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../../core/db/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/invoice.dart';
import '../models/print_job.dart';

class InvoiceFilter {
  final String search; // by number or customer
  final int fromMillis;
  final int toMillis;
  final bool includeVoided;

  const InvoiceFilter({
    this.search = '',
    this.fromMillis = 0,
    this.toMillis = 0,
    this.includeVoided = true,
  });
}

class InvoiceRepository {
  final Future<Database> Function() _open;

  InvoiceRepository({Future<Database> Function()? open})
      : _open = open ?? ((() => AppDatabase.open));

  /// Saves a finalized invoice inside a single transaction:
  /// 1) reserve the next invoice sequence, 2) build the number via the
  /// [buildNumber] callback, 3) insert the invoice, 4) insert item snapshots.
  /// If the composed number somehow already exists, the next sequence is
  /// reserved and the insert retried — numbers are never reused.
  Future<Invoice> finalize(Invoice draft, {required String Function(int seq) buildNumber}) async {
    final db = await _open();
    try {
      Invoice? saved;
      await db.transaction((txn) async {
        for (var attempt = 0; attempt < 100; attempt++) {
          final seq = await _reserveSequence(txn);
          final number = buildNumber(seq);
          final dup = await txn.query(
            'invoices',
            where: 'invoice_number = ? ',
            whereArgs: [number],
            limit: 1,
          );
          if (dup.isNotEmpty) continue; // reserve the next sequence
          saved = await _insertTxn(txn, draft, number, seq);
          return;
        }
      });
      if (saved == null) {
        throw AppException(ErrorCode.invoiceConflict, 'could not reserve an invoice number');
      }
      return saved!;
    } on DatabaseException catch (e) {
      throw AppException(ErrorCode.invoiceConflict, e.toString());
    }
  }

  Future<int> _reserveSequence(DatabaseExecutor txn) async {
    final rows = await txn.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['invoice_next'],
      limit: 1,
    );
    final current =
        int.tryParse(rows.isEmpty ? '1' : (rows.first['value'] as String? ?? '1')) ?? 1;
    await txn.update(
      'app_settings',
      {'value': (current + 1).toString()},
      where: 'key = ?',
      whereArgs: ['invoice_next'],
    );
    return current;
  }

  Future<Invoice> _insertTxn(DatabaseExecutor txn, Invoice draft, String number, int seq) async {
    final invoiceId = await txn.insert('invoices', {
      'invoice_number': number,
      'invoice_number_seq': seq,
      'created_at': draft.createdAt,
      'org_snapshot': draft.orgSnapshotJson,
      'receipt_snapshot': draft.receiptSnapshotJson,
      'app_settings_snapshot': draft.appSettingsSnapshotJson,
      'invoice_language': draft.invoiceLanguage.code,
      'date_system': draft.dateSystem,
      'date_style': draft.dateStyle,
      'numeral_format': draft.numeralFormat,
      'customer_json': draft.customer?.encode(),
      'discount_type': draft.totals.discountType.code,
      'discount_value': draft.totals.discountValue,
      'discount_amount': draft.totals.discountAmount,
      'tax_rate': draft.totals.taxRate,
      'tax_amount': draft.totals.taxAmount,
      'other_charges': draft.totals.otherCharges,
      'other_charges_note': draft.otherChargesNote,
      'subtotal': draft.totals.subtotalPaisa,
      'grand_total': draft.totals.grandTotal,
      'amount_paid': draft.totals.amountPaid,
      'balance_due': draft.totals.balanceDue,
      'payment_method': draft.paymentMethod.code,
      'notes': draft.notes,
      'status': draft.status.code,
      'updated_at': draft.createdAt,
    });
    final batch = txn.batch();
    for (var i = 0; i < draft.items.length; i++) {
      batch.insert('invoice_items', draft.items[i].toRow(invoiceId));
    }
    await batch.commit(noResult: true);
    return draft.copyWith(
      id: invoiceId,
      invoiceNumber: number,
      invoiceNumberSeq: seq,
      items: draft.items.asMap().entries.map((e) {
        final it = e.value;
        return InvoiceItem(
          id: 0,
          productId: it.productId,
          nameSnapshotEn: it.nameSnapshotEn,
          nameSnapshotNe: it.nameSnapshotNe,
          skuSnapshot: it.skuSnapshot,
          unitSnapshotEn: it.unitSnapshotEn,
          unitSnapshotNe: it.unitSnapshotNe,
          quantityMilli: it.quantityMilli,
          ratePaisa: it.ratePaisa,
          lineTotalPaisa: it.lineTotalPaisa,
          position: it.position,
        );
      }).toList(),
    );
  }

  Future<List<Invoice>> list(InvoiceFilter f, {int limit = 500, int offset = 0}) async {
    final db = await _open();
    final where = <String>[];
    final args = <Object?>[];
    if (!f.includeVoided) {
      where.add("status <> 'voided' AND status <> 'canceled'");
    }
    if (f.search.trim().isNotEmpty) {
      final s = f.search.trim();
      where.add('(i.invoice_number LIKE ? OR i.customer_json LIKE ? OR EXISTS '
          '(SELECT 1 FROM invoice_items it WHERE it.invoice_id = i.id AND '
          '(it.name_snapshot_en LIKE ? OR it.name_snapshot_ne LIKE ?)))');
      final needle = '%$s%';
      args.addAll([needle, needle, needle, needle]);
    }
    if (f.fromMillis > 0) {
      where.add('i.created_at >= ?');
      args.add(f.fromMillis);
    }
    if (f.toMillis > 0) {
      where.add('i.created_at <= ?');
      args.add(f.toMillis);
    }
    final rows = await db.rawQuery(
      'SELECT i.* FROM invoices i '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
      'ORDER BY i.created_at DESC LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
    final invoices = <Invoice>[];
    for (final r in rows) {
      final m = _rowToInvoice(r);
      final items = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [m.id],
        orderBy: 'position ASC, id ASC',
      );
      invoices.add(m.copyWith(items: items.map(InvoiceItem.fromRow).toList()));
    }
    return invoices;
  }

  Future<Invoice?> byId(int id) async {
    final db = await _open();
    final rows = await db.query('invoices', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final inv = _rowToInvoice(rows.first);
    final items = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC, id ASC',
    );
    return inv.copyWith(items: items.map(InvoiceItem.fromRow).toList());
  }

  Invoice _rowToInvoice(Map<String, Object?> r) {
    final totals = BillTotals(
      subtotalPaisa: r['subtotal'] as int? ?? 0,
      discountType: discountTypeFromCode(r['discount_type'] as String? ?? 'none'),
      discountValue: r['discount_value'] as int? ?? 0,
      discountAmount: r['discount_amount'] as int? ?? 0,
      taxRate: r['tax_rate'] as int? ?? 0,
      taxAmount: r['tax_amount'] as int? ?? 0,
      otherCharges: r['other_charges'] as int? ?? 0,
      grandTotal: r['grand_total'] as int? ?? 0,
      amountPaid: r['amount_paid'] as int? ?? 0,
      balanceDue: r['balance_due'] as int? ?? 0,
    );
    final customerJson = r['customer_json'] as String?;
    return Invoice(
      id: r['id'] as int,
      invoiceNumber: r['invoice_number'] as String? ?? '',
      invoiceNumberSeq: r['invoice_number_seq'] as int? ?? 0,
      createdAt: r['created_at'] as int? ?? 0,
      orgSnapshotJson: r['org_snapshot'] as String? ?? '{}',
      receiptSnapshotJson: r['receipt_snapshot'] as String? ?? '{}',
      appSettingsSnapshotJson: r['app_settings_snapshot'] as String? ?? '{}',
      invoiceLanguage: invoiceLanguageFromCode(r['invoice_language'] as String? ?? 'en'),
      dateSystem: r['date_system'] as String? ?? 'bs',
      dateStyle: r['date_style'] as String? ?? 'numeric',
      numeralFormat: r['numeral_format'] as String? ?? 'western',
      customer: customerJson == null || customerJson.isEmpty
          ? null
          : CustomerInfo.decode(customerJson),
      items: const [],
      totals: totals,
      paymentMethod: paymentMethodFromCode(r['payment_method'] as String?),
      otherChargesNote: r['other_charges_note'] as String? ?? '',
      notes: r['notes'] as String? ?? '',
      status: invoiceStatusFromCode(r['status'] as String? ?? 'finalized'),
      statusNote: r['status_note'] as String? ?? '',
      printCount: 0,
    );
  }

  /// Marks an invoice voided (kept in history, not reprinted).
  Future<void> voidInvoice(int id, String reason) async {
    final db = await _open();
    await db.update(
      'invoices',
      {
        'status': InvoiceStatus.canceled.code,
        'status_note': reason,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND status <> ? AND status <> ?',
      whereArgs: [id, InvoiceStatus.canceled.code, 'voided'],
    );
  }

  /// Updates an invoice transaction status (e.g. from processing to success or canceled).
  Future<void> updateInvoiceStatus(int id, InvoiceStatus status, {String note = ''}) async {
    final db = await _open();
    await db.update(
      'invoices',
      {
        'status': status.code,
        if (note.isNotEmpty) 'status_note': note,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Records a print attempt.
  Future<void> recordPrintJob({
    required int invoiceId,
    required PrintJobStatus status,
    required String? connectionType,
    required String errorMessage,
  }) async {
    final db = await _open();
    await db.insert('print_jobs', {
      'invoice_id': invoiceId,
      'attempted_at': DateTime.now().millisecondsSinceEpoch,
      'status': status.code,
      'connection_type': connectionType,
      'error_message': errorMessage,
    });
  }

  Future<List<PrintJob>> printJobsFor(int invoiceId) async {
    final db = await _open();
    final rows = await db.query(
      'print_jobs',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'attempted_at DESC',
    );
    return rows.map(PrintJob.fromRow).toList();
  }

  /// Number of successful print jobs for an invoice.
  Future<int> printCount(int invoiceId) async {
    final db = await _open();
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM print_jobs WHERE invoice_id = ? AND status = 'sent'",
      [invoiceId],
    );
    return rows.first['c'] as int? ?? 0;
  }

  static String encodeCustomer(CustomerInfo? c) =>
      c == null || c.isEmpty ? '' : c.encode();

  static CustomerInfo? decodeCustomer(String? json) =>
      (json == null || json.isEmpty) ? null : CustomerInfo.fromJson(jsonDecode(json) as Map<String, Object?>);
}
