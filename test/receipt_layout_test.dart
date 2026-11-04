import 'package:flutter_test/flutter_test.dart';
import 'package:xlab_billing/core/formatting/dates.dart';
import 'package:xlab_billing/shared/models/invoice.dart';
import 'package:xlab_billing/shared/services/escpos.dart';
import 'package:xlab_billing/shared/services/receipt_layout.dart';

ReceiptLayoutResult buildLayout({
  required String language,
  required bool devanagariNumerals,
}) {
  final data = ReceiptData(
    language: language,
    invoiceNumber: 'INV-000001',
    createdAtMillis: DateTime(2026, 1, 5).millisecondsSinceEpoch,
    org: const {},
    receipt: const {},
    items: const [
      ReceiptItemData(
        productId: 1,
        nameEn: 'Tea',
        nameNe: 'चिया',
        unitEn: 'cup',
        unitNe: 'कप',
        quantityMilli: 1000,
        ratePaisa: 15000,
        lineTotalPaisa: 15000,
      ),
    ],
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
    customer: null,
    otherChargesNote: '',
    notes: '',
  );
  final labels = ReceiptLabels(
    title: 'INVOICE',
    invoiceNumber: 'INV-000001',
    date: 'Date',
    particulars: 'Particulars',
    customer: 'Customer',
    customerPhone: 'Phone',
    customerAddress: 'Address',
    qtyLabel: 'Qty',
    unitLabel: 'Unit',
    rateLabel: 'Rate',
    amountLabel: 'Amount',
    subtotal: 'Subtotal',
    discount: 'Discount',
    tax: 'Tax',
    otherCharges: 'Other',
    grandTotal: 'Grand Total',
    paidLabel: 'Paid',
    dueLabel: 'Balance',
    changeLabel: 'Change',
    panCode: 'PAN:',
    vatCode: 'VAT:',
    phoneCode: 'Tel:',
    thankYou: 'Thank You',
  );
  return buildReceiptLayout(
    data: data,
    labels: labels,
    currencySymbol: 'NPR',
    paperWidthMm: 58,
    devanagariNumerals: devanagariNumerals,
    dateSystem: DateSystem.ad,
    dateStyle: DateStyle.numeric,
    dateWithTime: false,
    quantityPrecision: 2,
  );
}

void main() {
  test('English (ASCII) layout renders as text, Devanagari as raster', () {
    final en = buildLayout(language: 'en', devanagariNumerals: false);
    expect(en.requiresRaster, isFalse);
    expect(en.textElements, isNotEmpty);
    final enTexts = en.textElements.map((e) => e is StyleLine ? e.text : '').join();
    expect(enTexts, contains('Thank You'));

    final ne = buildLayout(language: 'ne', devanagariNumerals: true);
    expect(ne.requiresRaster, isTrue);
    expect(ne.imageLines, isNotEmpty);
  });

  test('items render as a fixed-width table without a balance row', () {
    final en = buildLayout(language: 'en', devanagariNumerals: false);
    final columns = en.textElements.whereType<ColumnsLine>().toList();
    // Header + one item row.
    expect(columns.where((c) => !receiptTableColumnsBlank(c.cells)), hasLength(2));
    expect(columns.first.cells, [
      'Particulars',
      'Qty',
      'Rate',
      'Amount',
    ]);
    expect(columns.last.cells[1], '1.00 cup');
    // Balance/due is no longer printed on receipts.
    final printed = en.textElements
        .map((e) => switch (e) {
              StyleLine() => e.text,
              TwoPartLine() => '${e.left} ${e.right}',
              _ => '',
            })
        .join('\n');
    expect(printed.contains('Balance'), isFalse);

    final ne = buildLayout(language: 'ne', devanagariNumerals: true);
    final imageTable = ne.imageLines.whereType<ImageColumns>().toList();
    // Test fixture supplies English labels; header + one item row, with the
    // item name living in the Particulars column.
    expect(imageTable.first.cells,
        ['Particulars', 'Qty', 'Rate', 'Amount']);
    expect(imageTable.last.cells.first, 'चिया');
    expect(imageTable.last.cells[1], '१.०० कप');
    expect(imageTable.length, 2); // header + item row
  });

  test('INVOICE / बिल title appears below organization details and above invoice meta', () {
    final data = ReceiptData(
      language: 'en',
      invoiceNumber: 'INV-000001',
      createdAtMillis: DateTime(2026, 1, 5).millisecondsSinceEpoch,
      org: const {
        'name_en': 'Kaicho Group Pvt Ltd',
        'address_en': 'Rupandehi',
        'pan_number': '1234567',
      },
      receipt: const {'show_address': 1, 'show_pan_vat': 1},
      items: const [],
      totals: const BillTotals(
        subtotalPaisa: 1000,
        discountType: DiscountType.none,
        discountValue: 0,
        discountAmount: 0,
        taxRate: 0,
        taxAmount: 0,
        otherCharges: 0,
        grandTotal: 1000,
        amountPaid: 0,
        balanceDue: 1000,
      ),
      customer: null,
    );
    const labels = ReceiptLabels(
      title: 'INVOICE',
      invoiceNumber: 'Invoice Number',
      date: 'Date',
      particulars: 'Particulars',
      customer: 'Customer',
      customerPhone: 'Phone',
      customerAddress: 'Address',
      qtyLabel: 'Qty',
      unitLabel: 'Unit',
      rateLabel: 'Rate',
      amountLabel: 'Amount',
      subtotal: 'Subtotal',
      discount: 'Discount',
      tax: 'Tax',
      otherCharges: 'Other',
      grandTotal: 'Grand Total',
      paidLabel: 'Paid',
      dueLabel: 'Balance',
      changeLabel: 'Change',
      panCode: 'PAN:',
      vatCode: 'VAT:',
      phoneCode: 'Tel:',
      thankYou: 'Thank You',
    );
    final layout = buildReceiptLayout(
      data: data,
      labels: labels,
      currencySymbol: 'NPR',
      paperWidthMm: 80,
      devanagariNumerals: false,
      dateSystem: DateSystem.ad,
      dateStyle: DateStyle.numeric,
      dateWithTime: false,
      quantityPrecision: 2,
    );

    final imgTexts = [
      for (final l in layout.imageLines)
        if (l is ImageParagraph) l.text,
    ];
    final orgIdx = imgTexts.indexOf('Kaicho Group Pvt Ltd');
    final panIdx = imgTexts.indexWhere((t) => t.startsWith('PAN:'));
    final titleIdx = imgTexts.indexOf('INVOICE');
    final invNoIdx = imgTexts.indexWhere((t) => t.startsWith('Invoice Number:'));
    expect(orgIdx, greaterThanOrEqualTo(0));
    expect(panIdx, greaterThan(orgIdx));
    expect(titleIdx, greaterThan(panIdx));
    expect(invNoIdx, greaterThan(titleIdx));
  });
}

bool receiptTableColumnsBlank(List<String> cells) =>
    cells.every((c) => c.trim().isEmpty);

