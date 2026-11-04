/// Orchestrates rendering and printing. Bridges the layout engines,
/// transports and snapshot-based data for both live bills and replays of
/// historical invoices.
///
/// Transmission success ≠ confirmed physical print — the result of the ESC/POS
/// protocol cannot be verified. The UI therefore says "sent; check paper".
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../core/formatting/dates.dart';
import '../../localization/app_localizations.dart';
import '../models/invoice.dart';
import '../models/printer.dart';
import 'escpos.dart';
import 'receipt_bitmap.dart';
import 'receipt_layout.dart';
import 'transports.dart';

/// Rendered receipt for one job.
class ReceiptBuildResult {
  final Uint8List bytes;
  final bool usedRaster;
  final RasterBitmap? preview;

  const ReceiptBuildResult(this.bytes, {required this.usedRaster, this.preview});
}

class PrintOrchestrator {
  const PrintOrchestrator();

  /// Minimum line feeds needed to advance the last printed line past the
  /// XTKP607UL auto-cutter blade (~15 mm above the printhead).
  static const int baseCutFeedLines = 5;

  /// Extra line feeds added before cutting when `bottom_margin_on_receipt`
  /// is enabled, leaving a bottom margin that matches the ~15 mm top margin
  /// created by the cutter-to-printhead offset.
  static const int extraBottomMarginFeedLines = 4;

  static int cutFeedLinesFor({required bool bottomMargin}) =>
      bottomMargin ? baseCutFeedLines + extraBottomMarginFeedLines : baseCutFeedLines;

  /// Loads the generated localizations for a language code.
  static Future<AppLocalizations> l10nOf(String code) async {
    final delegate = AppLocalizations.delegate;
    return (await delegate.load(Locale(code)));
  }

  static ReceiptLabels labelsOf(AppLocalizations l) => ReceiptLabels(
        title: l.invoiceTitle,
        invoiceNumber: l.invoiceNumber,
        date: l.date,
        particulars: l.particularsLabel,
        customer: l.customer,
        customerPhone: l.customerPhone,
        customerAddress: l.customerAddress,
        qtyLabel: l.qtyLabel,
        unitLabel: l.unitLabel,
        rateLabel: l.rateLabel,
        amountLabel: l.amountLabel,
        subtotal: l.subtotal,
        discount: l.discount,
        tax: l.tax,
        otherCharges: l.otherCharges,
        grandTotal: l.grandTotal,
        paidLabel: l.paidLabel,
        dueLabel: l.dueLabel,
        changeLabel: l.changeLabel,
        panCode: l.panCode,
        vatCode: l.vatCode,
        phoneCode: l.phoneCode,
        thankYou: l.thankYou,
      );

  /// Decodes snapshot JSON maps stored on the invoice row.
  static (Map<String, Object?> org, Map<String, Object?> receipt, Map<String, Object?> app)
      snapshotsOf(Invoice invoice) {
    final org = decodeStringMap(invoice.orgSnapshotJson);
    final receipt = decodeStringMap(invoice.receiptSnapshotJson);
    final app = decodeStringMap(invoice.appSettingsSnapshotJson);
    return (org, receipt, app);
  }

  static Map<String, Object?> decodeStringMap(String json) {
    if (json.isEmpty || json == '{}') return {};
    final decoded = jsonDecode(json);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  static ReceiptData receiptDataFor(Invoice invoice, {String? languageOverride}) {
    final (org, receipt, app) = snapshotsOf(invoice);
    // Empty override = no override: '' must never reach the localizations
    // delegate as a locale (loading an empty languageCode throws
    // "unsupported locale" and blanks the preview).
    final langCode = (languageOverride == null || languageOverride.isEmpty)
        ? invoice.invoiceLanguage.code
        : languageOverride;
    return ReceiptData(
      language: langCode,
      invoiceNumber: invoice.invoiceNumber,
      createdAtMillis: invoice.createdAt,
      org: org,
      receipt: receipt,
      items: [
        for (final it in invoice.items)
          ReceiptItemData(
            productId: it.productId,
            nameEn: it.nameSnapshotEn,
            nameNe: it.nameSnapshotNe,
            unitEn: it.unitSnapshotEn,
            unitNe: it.unitSnapshotNe,
            quantityMilli: it.quantityMilli,
            ratePaisa: it.ratePaisa,
            lineTotalPaisa: it.lineTotalPaisa,
          ),
      ],
      totals: invoice.totals,
      customer: invoice.customer,
      otherChargesNote: invoice.otherChargesNote,
      notes: invoice.notes,
    );
  }

  /// Layout for [invoice] in the effective language.
  Future<ReceiptLayoutResult> layoutFor(
    Invoice invoice, {
    String? languageOverride,
    int? paperWidthMm,
  }) async {
    final data = receiptDataFor(invoice, languageOverride: languageOverride);
    final app = decodeStringMap(invoice.appSettingsSnapshotJson);
    final symbol = data.nepali ? 'रु.' : 'NPR';
    final paperMm = paperWidthMm ?? _paperWidthOf(data.receipt);
    final hasExplicitOverride =
        languageOverride != null && languageOverride.isNotEmpty;
    final useDevanagari = hasExplicitOverride
        ? data.nepali
        : (data.nepali || invoice.numeralFormat == 'devanagari');

    final l10n = await l10nOf(data.language);
    return buildReceiptLayout(
      data: data,
      labels: labelsOf(l10n),
      currencySymbol: symbol,
      paperWidthMm: paperMm,
      devanagariNumerals: useDevanagari,
      dateSystem: invoice.dateSystem == 'ad' ? DateSystem.ad : DateSystem.bs,
      dateStyle: invoice.dateStyle == 'numeric' ? DateStyle.numeric : DateStyle.longMonth,
      // The toggle lives in app settings; the receipt-design snapshot has no
      // such key, so reading it there always fell back to "show time".
      dateWithTime: _boolFlag(app['show_time_on_receipt'], true),
      quantityPrecision: int.tryParse('${app['quantity_precision'] ?? 2}') ?? 2,
    );
  }

  /// Settings snapshots store text flags ('1'/'0' or 'true'/'false').
  static bool _boolFlag(Object? value, bool dflt) {
    switch ('$value') {
      case '1':
      case 'true':
        return true;
      case '0':
      case 'false':
        return false;
      default:
        return dflt;
    }
  }

  static int _paperWidthOf(Map<String, Object?> rc) {
    final raw = rc['paper_width_mm'];
    final v = raw is int ? raw : int.tryParse('$raw');
    return v ?? 58;
  }

  /// Preview bitmap (raster of the image layout) — WYSIWYG for the screen.
  Future<RasterBitmap?> renderPreview(
    Invoice invoice, {
    String? languageOverride,
    int? paperWidthMm,
  }) async {
    try {
      final layout = await layoutFor(
        invoice,
        languageOverride: languageOverride,
        paperWidthMm: paperWidthMm,
      );
      final data = receiptDataFor(invoice, languageOverride: languageOverride);
      final logo = await _logoBytesFor(data);
      return await renderReceiptBitmap(
        lines: layout.imageLines,
        widthDots: layout.widthDots,
        logoBytes: logo,
        textScale: _textSizeScale(data.receipt),
      );
    } catch (_) {
      return null;
    }
  }

  /// Receipt `text_size` setting → raster font scale.
  static double _textSizeScale(Map<String, Object?> rc) => switch (rc['text_size']) {
        'small' => 0.9,
        'large' => 1.12,
        _ => 1.0,
      };

  Future<Uint8List?> _logoBytesFor(ReceiptData data) async {
    final show = (data.receipt['show_logo'] as int? ?? 0) != 0;
    final path = data.receipt['logo_path'] as String? ?? '';
    if (!show || path.isEmpty) return null;
    try {
      final f = File(path);
      if (!f.existsSync()) return null;
      return await f.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Bytes ready to send for the printer [config].
  Future<ReceiptBuildResult> buildPrintBytes(
    Invoice invoice,
    PrinterConfig config, {
    String? languageOverride,
  }) async {
    final layout = await layoutFor(
      invoice,
      languageOverride: languageOverride,
      paperWidthMm: config.paperWidthMm,
    );
    final data = receiptDataFor(invoice, languageOverride: languageOverride);

    var raster = layout.requiresRaster;
    switch (config.renderingMode) {
      case RenderingMode.image:
        raster = true;
        break;
      case RenderingMode.text:
        // Devanagari / non-ASCII content cannot be printed in 7-bit ESC/POS
        // character mode, so layout.requiresRaster always forces raster.
        raster = layout.requiresRaster;
        break;
      case RenderingMode.auto:
        // keep detected value
        break;
    }

    final logo = await _logoBytesFor(data);
    final app = decodeStringMap(invoice.appSettingsSnapshotJson);
    final feedLines = cutFeedLinesFor(
      bottomMargin: _boolFlag(app['bottom_margin_on_receipt'], false),
    );

    if (raster) {
      final bitmap = await renderReceiptBitmap(
        lines: layout.imageLines,
        widthDots: layout.widthDots,
        logoBytes: logo,
        textScale: _textSizeScale(data.receipt),
      );
      final bytes = buildEscPosBytes(
        [
          RasterImage(
            widthDots: bitmap.widthDots,
            heightDots: bitmap.heightDots,
            packedRows: bitmap.packedRows,
          ),
        ],
        charCols: charColumnsFor(config.paperWidthMm),
        enableCut: config.enableCut,
        enableBeep: config.enableBeep,
        enableDrawer: config.enableDrawer,
        feedLinesAtEnd: feedLines,
      );
      return ReceiptBuildResult(
        Uint8List.fromList(bytes),
        usedRaster: true,
        preview: bitmap,
      );
    }

    final bytes = buildEscPosBytes(
      layout.textElements,
      charCols: charColumnsFor(config.paperWidthMm),
      enableCut: config.enableCut,
      enableBeep: config.enableBeep,
      enableDrawer: config.enableDrawer,
      feedLinesAtEnd: feedLines,
    );
    return ReceiptBuildResult(
      Uint8List.fromList(bytes),
      usedRaster: false,
      preview: null,
    );
  }

  /// Full send flow for one print attempt.
  Future<void> sendBytes(PrinterConfig config, Uint8List bytes,
      {ReceiptTransport? transport}) async {
    final t = transport ??
        _transportFor(config);
    try {
      await t.open();
      await t.send(bytes);
    } finally {
      await t.close();
    }
  }

  static ReceiptTransport _transportFor(PrinterConfig config) {
    switch (config.connectionType) {
      case ConnectionType.lan:
        return LanReceiptTransport(host: config.host, port: config.port);
      case ConnectionType.usb:
        return UsbReceiptTransport(
          vendorId: config.usbVendorId ?? 0,
          productId: config.usbProductId ?? 0,
        );
    }
  }

  /// Reconnect/status test: opens + closes without sending data.
  Future<void> testConnection(PrinterConfig config,
      {ReceiptTransport? transport}) async {
    final t = transport ?? _transportFor(config);
    try {
      await t.open();
    } finally {
      await t.close();
    }
  }

  /// Builds the bytes for a self test receipt (both engines exercised).
  Future<Uint8List> buildTestReceiptBytes(
    PrinterConfig config, {
    bool bottomMargin = false,
  }) async {
    final bitmap = await renderReceiptBitmap(
      lines: [
        const ImageParagraph('XLab XTKP607UL', align: ReceiptAlign.center, bold: true, sizePx: 22),
        const ImageParagraph('Test Receipt / टेस्ट रसिद', align: ReceiptAlign.center, sizePx: 18),
        const ImageRule(),
        const ImageParagraph('Nepali: कस्तो छ? म राम्रो छु। ०१२३४५६७८९', sizePx: 18),
        const ImageParagraph('English English English English English English English English that is longer and must wrap around the paper width nicely.',
            sizePx: 18),
        const ImageRow('Qty 2 x 25.50', '51.00', dotFill: true, sizePx: 18),
        const ImageParagraph('धन्यवाद / Thank You', align: ReceiptAlign.center, bold: true, sizePx: 20),
      ],
      widthDots: dotsForWidthMm(config.paperWidthMm),
    );
    final bytes = buildEscPosBytes(
      [
        const StyleLine('XLab XTKP607UL self-test', style: ReceiptStyle(bold: true)),
        StyleLine(
          'LAN/IP: ${config.host.isEmpty ? '-' : '${config.host}:${config.port}'}  USB: ${config.usbVendorId == null ? '-' : '${config.usbVendorId}:${config.usbProductId}'}',
        ),
        StyleLine('Paper: ${config.paperWidthMm}mm  Mode: ${config.renderingMode.code}'),
        RasterImage(
          widthDots: bitmap.widthDots,
          heightDots: bitmap.heightDots,
          packedRows: bitmap.packedRows,
        ),
      ],
      charCols: charColumnsFor(config.paperWidthMm),
      enableCut: config.enableCut,
      enableBeep: config.enableBeep,
      enableDrawer: config.enableDrawer,
      feedLinesAtEnd: cutFeedLinesFor(bottomMargin: bottomMargin),
    );
    return Uint8List.fromList(bytes);
  }
}
