import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xlab_billing/shared/models/invoice.dart';
import 'package:xlab_billing/shared/models/printer.dart';
import 'package:xlab_billing/shared/services/escpos.dart';
import 'package:xlab_billing/shared/services/print_service.dart';
import 'package:xlab_billing/shared/services/transports.dart';

Invoice _invoice({
  InvoiceLanguage language = InvoiceLanguage.en,
  String numeralFormat = 'western',
  String appSettingsSnapshotJson = '{}',
}) {
  return Invoice(
    id: 1,
    invoiceNumber: 'INV-000001',
    invoiceNumberSeq: 1,
    createdAt: DateTime(2026, 1, 5).millisecondsSinceEpoch,
    orgSnapshotJson: '{}',
    receiptSnapshotJson: '{}',
    appSettingsSnapshotJson: appSettingsSnapshotJson,
    invoiceLanguage: language,
    dateSystem: 'ad',
    dateStyle: 'long',
    numeralFormat: numeralFormat,
    customer: null,
    items: const [],
    totals: BillTotals(
      subtotalPaisa: 0,
      discountType: DiscountType.none,
      discountValue: 0,
      discountAmount: 0,
      taxRate: 0,
      taxAmount: 0,
      otherCharges: 0,
      grandTotal: 0,
      amountPaid: 0,
      balanceDue: 0,
    ),
    paymentMethod: PaymentMethod.cash,
    otherChargesNote: '',
    notes: '',
    status: InvoiceStatus.finalized,
    statusNote: '',
    printCount: 0,
  );
}

void main() {
  final config = PrinterConfig(
    id: 1,
    displayName: 'LAN test',
    connectionType: ConnectionType.lan,
    host: '192.168.1.50',
    port: 9100,
    usbVendorId: null,
    usbProductId: null,
    usbDeviceName: '',
    paperWidthMm: 58,
    renderingMode: RenderingMode.auto,
    enableCut: true,
    enableBeep: false,
    enableDrawer: false,
    isSelected: true,
    updatedAt: 0,
  );

  test('ESC/POS builder emits init sequence', () {
    final bytes = buildEscPosBytes(
      [const StyleLine('INVOICE')],
      charCols: 56,
      enableCut: true,
      enableBeep: false,
      enableDrawer: false,
      feedLinesAtEnd: 2,
    );
    expect(bytes[0], 0x1B);
    expect(bytes[1], 0x40); // ESC @
  });

  test('ESC/POS builder emits a full cut (GS V 0) when enabled', () {
    final withCut = buildEscPosBytes(
      [const StyleLine('X')],
      charCols: 32,
      enableCut: true,
      feedLinesAtEnd: 0,
    );
    // GS V 0 = full cut; must be the final control sequence.
    expect(withCut[withCut.length - 3], gs);
    expect(withCut[withCut.length - 2], 0x56);
    expect(withCut[withCut.length - 1], 0x00);

    final withoutCut = buildEscPosBytes(
      [const StyleLine('X')],
      charCols: 32,
      enableCut: false,
      feedLinesAtEnd: 0,
    );
    expect(withoutCut[withoutCut.length - 1], 0x0A); // plain final feed only
  });

  test('dotsForWidthMm matches the real 203-dpi head classes', () {
    // Printable band is fixed by the head, not the roll: 58 mm-class ≈ 48 mm
    // (384 dots), 80 mm-class ≈ 72 mm (576 dots). The old `mm * 8 - 8`
    // formula produced 456/632 and made printers squash the bitmap.
    expect(dotsForWidthMm(58), 384);
    expect(dotsForWidthMm(80), 576);
  });

  test('columnsText lays out a fixed-width item table row', () {
    final line = columnsText(
      ['Tea', '2', '150.00', '300.00'],
      charCols: 32,
    );
    expect(line.length, 32);
    final cols = tableColumnWidths(
      ['Tea', '2', '150.00', '300.00'],
      charCols: 32,
      fractions: receiptTableFractions,
    );
    expect(line.substring(0, cols[0]).trim(), 'Tea');
    expect(line.substring(cols[0] + cols[1]).trim().split(' '),
        ['150.00', '300.00']);
    // Right-aligned columns never truncate their content.
    expect(line.contains('300.00'), isTrue);
  });

  test('twoPartText and alignText lay out to exact charCols without overflowing', () {
    final sub = twoPartText('Subtotal', 'NPR 70.00', charCols: 48);
    expect(sub.length, 48);
    expect(sub.startsWith('Subtotal'), isTrue);
    expect(sub.endsWith('NPR 70.00'), isTrue);

    final grand = twoPartText('Grand Total', 'NPR 70.00', charCols: 48);
    expect(grand.length, 48);
    expect(grand.startsWith('Grand Total'), isTrue);
    expect(grand.endsWith('NPR 70.00'), isTrue);

    final centered = alignText(
      'INVOICE',
      charCols: 48,
      align: ReceiptAlign.center,
    );
    expect(centered.length, 48);
    expect(centered.trim(), 'INVOICE');
  });

  test('ASCII invoice uses text mode; Devanagari forces raster', () async {
    final ascii = await PrintOrchestrator().buildPrintBytes(
      _invoice(),
      config,
      languageOverride: 'en',
    );
    expect(ascii.usedRaster, isFalse);
    expect(ascii.bytes.length, greaterThan(10));

    final nepali = await PrintOrchestrator().buildPrintBytes(
      _invoice(language: InvoiceLanguage.ne, numeralFormat: 'devanagari'),
      config,
      languageOverride: 'ne',
    );
    expect(nepali.usedRaster, isTrue);
  });

  test('test receipt bytes build through raster and end with the full cut', () async {
    final bytes = await PrintOrchestrator().buildTestReceiptBytes(config);
    expect(bytes.length, greaterThan(10));
    // Ends with GS V 0 (full cut) after the trailing feed.
    expect(bytes[bytes.length - 3], gs);
    expect(bytes[bytes.length - 2], 0x56);
    expect(bytes[bytes.length - 1], 0x00);

    final withMargin = await PrintOrchestrator().buildTestReceiptBytes(
      config,
      bottomMargin: true,
    );
    expect(
      withMargin.length - bytes.length,
      PrintOrchestrator.extraBottomMarginFeedLines,
    );
  });

  test('bottom_margin_on_receipt adds extra trailing feed lines before cut', () async {
    final compact = await PrintOrchestrator().buildPrintBytes(
      _invoice(
        language: InvoiceLanguage.ne,
        numeralFormat: 'devanagari',
        appSettingsSnapshotJson: '{"bottom_margin_on_receipt":"false"}',
      ),
      config,
      languageOverride: 'ne',
    );
    final padded = await PrintOrchestrator().buildPrintBytes(
      _invoice(
        language: InvoiceLanguage.ne,
        numeralFormat: 'devanagari',
        appSettingsSnapshotJson: '{"bottom_margin_on_receipt":"true"}',
      ),
      config,
      languageOverride: 'ne',
    );
    expect(
      padded.bytes.length - compact.bytes.length,
      PrintOrchestrator.extraBottomMarginFeedLines,
    );
  });

  test('rasterImageBytes encodes xL/xH in bytes (widthDots/8), never dots', () {
    for (final widthDots in const [384, 576]) {
      final rowBytes = widthDots ~/ 8;
      const heightDots = 150;
      final payload = Uint8List.fromList(
        List<int>.generate(rowBytes * heightDots, (i) => i & 0xFF),
      );
      final encoded = rasterImageBytes(
        RasterImage(
          widthDots: widthDots,
          heightDots: heightDots,
          packedRows: payload,
        ),
      );

      // Walk every GS v 0 band and verify the header matches the exact
      // payload slice that follows (if xL/xH were widthDots instead of
      // rowBytes, the printer would wait for 8x as many bytes and hang).
      var offset = 0;
      var totalRows = 0;
      final reconstructed = BytesBuilder();
      while (offset < encoded.length) {
        expect(encoded[offset], gs);
        expect(encoded[offset + 1], 0x76);
        expect(encoded[offset + 2], 0x30);
        expect(encoded[offset + 3], 0x00);
        final xBytes = encoded[offset + 4] | (encoded[offset + 5] << 8);
        final yRows = encoded[offset + 6] | (encoded[offset + 7] << 8);
        expect(xBytes, rowBytes,
            reason: 'GS v 0 xL/xH must be horizontal byte count ($rowBytes), '
                'not dot width ($widthDots)');
        expect(yRows, greaterThan(0));
        expect(yRows, lessThanOrEqualTo(maxRasterBandRows));

        final bandLen = xBytes * yRows;
        final dataStart = offset + 8;
        final dataEnd = dataStart + bandLen;
        expect(dataEnd, lessThanOrEqualTo(encoded.length));
        reconstructed.add(encoded.sublist(dataStart, dataEnd));
        totalRows += yRows;
        offset = dataEnd;
      }
      expect(offset, encoded.length);
      expect(totalRows, heightDots);
      expect(reconstructed.toBytes(), payload);
    }
  });

  test('LanReceiptTransport delivers back-to-back print jobs cleanly', () async {
    final receivedJobs = <Uint8List>[];
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    final serverSub = server.listen((client) {
      final builder = BytesBuilder();
      client.listen(
        builder.add,
        onDone: () {
          receivedJobs.add(builder.toBytes());
          client.close();
        },
      );
    });
    addTearDown(serverSub.cancel);

    final lanConfig = config.copyWith(
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
    );
    final orchestrator = const PrintOrchestrator();
    final testBytes = await orchestrator.buildTestReceiptBytes(lanConfig);

    // First test print + second test print back-to-back on the same listener.
    for (var i = 0; i < 2; i++) {
      final transport = LanReceiptTransport(
        host: lanConfig.host,
        port: lanConfig.port,
        chunkDelay: Duration.zero,
      );
      await orchestrator.sendBytes(lanConfig, testBytes, transport: transport);
    }

    // Wait briefly for loopback onDone callbacks to record both jobs.
    for (var i = 0; i < 20 && receivedJobs.length < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(receivedJobs.length, 2);
    expect(receivedJobs[0], testBytes);
    expect(receivedJobs[1], testBytes);
  });
}
