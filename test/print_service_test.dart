/// Language-override resolution for receipt rendering.
///
/// The preview stores the "follow the invoice" choice as an empty string;
/// an override of '' must behave exactly like no override. Reaching the
/// localizations delegate with an empty languageCode throws (unsupported
/// locale) and the preview fails to render.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:xlab_billing/shared/models/invoice.dart';
import 'package:xlab_billing/shared/models/printer.dart';
import 'package:xlab_billing/shared/services/print_service.dart';
import 'package:xlab_billing/shared/services/receipt_layout.dart';

Invoice _neInvoice({String appSnapshot = '{}'}) =>
    Invoice(
      id: 1,
      invoiceNumber: 'INV-000001',
      invoiceNumberSeq: 1,
      createdAt: 0,
      orgSnapshotJson: '{}',
      receiptSnapshotJson: '{}',
      appSettingsSnapshotJson: appSnapshot,
      invoiceLanguage: InvoiceLanguage.ne,
      dateSystem: 'ad',
      dateStyle: 'numeric',
      numeralFormat: 'western',
      customer: null,
      items: [], // item data irrelevant to language resolution
      totals: BillTotals(
        subtotalPaisa: 15000,
        discountType: DiscountType.none,
        discountValue: 0,
        discountAmount: 0,
        taxRate: 0,
        taxAmount: 0,
        otherCharges: 0,
        grandTotal: 15000,
        amountPaid: 0,
        balanceDue: 15000,
      ),
      paymentMethod: PaymentMethod.cash,
      otherChargesNote: '',
      notes: '',
      status: InvoiceStatus.finalized,
      statusNote: '',
      printCount: 0,
    );

void main() {
  test('receiptDataFor: no override uses the invoice language', () {
    expect(PrintOrchestrator.receiptDataFor(_neInvoice()).language, 'ne');
  });

  test('receiptDataFor: empty-string override is treated as no override', () {
    final data =
        PrintOrchestrator.receiptDataFor(_neInvoice(), languageOverride: '');
    expect(data.language, 'ne',
        reason: "override '' must not be handed to the l10n delegate "
            'as a locale code');
  });

  test('receiptDataFor: explicit override wins', () {
    final data =
        PrintOrchestrator.receiptDataFor(_neInvoice(), languageOverride: 'en');
    expect(data.language, 'en');
  });

  test('layoutFor renders with an empty override (no unsupported locale)',
      () async {
    final orch = PrintOrchestrator();
    final layout = await orch.layoutFor(_neInvoice(), languageOverride: '');
    expect(layout.imageLines, isNotEmpty);
  });

  test('layoutFor: show_time_on_receipt from the app snapshot controls the time',
      () async {
    final timeRe = RegExp(r'\d{1,2}:\d{2}');
    String receiptTexts(ReceiptLayoutResult layout) => [
          for (final l in layout.imageLines)
            if (l is ImageParagraph) l.text,
        ].join('\n');
    final orch = PrintOrchestrator();

    final on = receiptTexts(
      await orch.layoutFor(
        _neInvoice(appSnapshot: '{"show_time_on_receipt":"true"}'),
        languageOverride: 'en',
      ),
    );
    expect(timeRe.hasMatch(on), isTrue,
        reason: 'an enabled time flag must append HH:mm to the date line');

    final off = receiptTexts(
      await orch.layoutFor(
        _neInvoice(appSnapshot: '{"show_time_on_receipt":"false"}'),
        languageOverride: 'en',
      ),
    );
    expect(timeRe.hasMatch(off), isFalse,
        reason: 'a disabled time flag must not show a time (was always on: '
            'the flag was read from the receipt-design snapshot, which has '
            'no such key)');

    final legacy = receiptTexts(
      await orch.layoutFor(_neInvoice(), languageOverride: 'en'),
    );
    expect(timeRe.hasMatch(legacy), isTrue,
        reason: 'snapshots without the key keep the model default (on)');
  });

  test('buildPrintBytes honors languageOverride=ne even on an English invoice or text-mode config', () async {
    const orch = PrintOrchestrator();
    final enInv = Invoice(
      id: 2,
      invoiceNumber: 'INV-000002',
      invoiceNumberSeq: 2,
      createdAt: 0,
      orgSnapshotJson: '{}',
      receiptSnapshotJson: '{}',
      appSettingsSnapshotJson: '{}',
      invoiceLanguage: InvoiceLanguage.en,
      dateSystem: 'bs',
      dateStyle: 'long',
      numeralFormat: 'western',
      customer: null,
      items: const [],
      totals: const BillTotals(
        subtotalPaisa: 7000,
        discountType: DiscountType.none,
        discountValue: 0,
        discountAmount: 0,
        taxRate: 0,
        taxAmount: 0,
        otherCharges: 0,
        grandTotal: 7000,
        amountPaid: 0,
        balanceDue: 7000,
      ),
      paymentMethod: PaymentMethod.cash,
      otherChargesNote: '',
      notes: '',
      status: InvoiceStatus.finalized,
      statusNote: '',
      printCount: 0,
    );
    const cfg = PrinterConfig(
      id: 1,
      displayName: 'Printer',
      connectionType: ConnectionType.lan,
      host: '192.168.1.50',
      port: 9100,
      usbVendorId: null,
      usbProductId: null,
      usbDeviceName: '',
      paperWidthMm: 80,
      renderingMode: RenderingMode.text,
      enableCut: true,
      enableBeep: false,
      enableDrawer: false,
      isSelected: true,
      updatedAt: 0,
    );

    final built = await orch.buildPrintBytes(
      enInv,
      cfg,
      languageOverride: 'ne',
    );
    expect(built.usedRaster, isTrue,
        reason: 'Nepali override must rasterize Devanagari labels/digits even if config had RenderingMode.text');
  });

  test('layoutFor renders PAN and VAT on receipt in both English and Nepali when show_pan_vat is enabled', () async {
    const orch = PrintOrchestrator();
    final inv = Invoice(
      id: 3,
      invoiceNumber: 'INV-000003',
      invoiceNumberSeq: 3,
      createdAt: 0,
      orgSnapshotJson: '{"name_en":"Kaicho Group Pvt Ltd","name_ne":"काइचो ग्रुप प्रा लि","pan_number":"1234567","vat_number":""}',
      receiptSnapshotJson: '{"show_pan_vat":1}',
      appSettingsSnapshotJson: '{}',
      invoiceLanguage: InvoiceLanguage.en,
      dateSystem: 'bs',
      dateStyle: 'long',
      numeralFormat: 'western',
      customer: null,
      items: const [],
      totals: const BillTotals(
        subtotalPaisa: 7000,
        discountType: DiscountType.none,
        discountValue: 0,
        discountAmount: 0,
        taxRate: 0,
        taxAmount: 0,
        otherCharges: 0,
        grandTotal: 7000,
        amountPaid: 0,
        balanceDue: 7000,
      ),
      paymentMethod: PaymentMethod.cash,
      otherChargesNote: '',
      notes: '',
      status: InvoiceStatus.finalized,
      statusNote: '',
      printCount: 0,
    );

    final enLayout = await orch.layoutFor(inv, languageOverride: 'en');
    final enParagraphs = [
      for (final l in enLayout.imageLines)
        if (l is ImageParagraph) l.text,
    ].join('\n');
    expect(enParagraphs, contains('PAN: 1234567'));

    final neLayout = await orch.layoutFor(inv, languageOverride: 'ne');
    final neParagraphs = [
      for (final l in neLayout.imageLines)
        if (l is ImageParagraph) l.text,
    ].join('\n');
    expect(neParagraphs, contains('१२३४५६७'));
  });
}
