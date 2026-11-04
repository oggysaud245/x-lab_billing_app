/// Raster renderer regression: every receipt paragraph must produce ink.
///
/// The engine paints glyphs with a transparent fill when `ui.TextStyle`
/// carries neither a color nor a foreground painter — the result is a blank
/// receipt showing only the rule lines while text still reserves its layout
/// height. These tests pin explicit black fills in `renderReceiptBitmap`.
library;

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:xlab_billing/core/formatting/dates.dart';
import 'package:xlab_billing/shared/models/invoice.dart';
import 'package:xlab_billing/shared/services/escpos.dart';
import 'package:xlab_billing/shared/services/receipt_bitmap.dart';
import 'package:xlab_billing/shared/services/receipt_layout.dart';

/// flutter_test does not auto-load pubspec fonts; register the receipt fonts
/// so shaping matches what a real device does.
Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(rootBundle.load(path));
  }
  await loader.load();
}

/// Set bits in the 1-bit raster = dark dots that would print.
int inkBits(RasterBitmap bitmap) {
  var n = 0;
  for (final byte in bitmap.packedRows) {
    var v = byte;
    while (v != 0) {
      v &= v - 1;
      n++;
    }
  }
  return n;
}

Future<RasterBitmap> renderLines(List<ImageLine> lines) => renderReceiptBitmap(
      lines: lines,
      widthDots: dotsForWidthMm(58),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFont('NotoSans', [
      'assets/fonts/NotoSans-Regular.ttf',
      'assets/fonts/NotoSans-Bold.ttf',
    ]);
    await _loadFont('NotoSansDevanagari', [
      'assets/fonts/NotoSansDevanagari-Regular.ttf',
      'assets/fonts/NotoSansDevanagari-Bold.ttf',
    ]);
  });

  test('Latin text paragraphs rasterize dark dots', () async {
    final textLines = const [
      ImageParagraph('Tea 1 x 150.00'),
      ImageParagraph('Subtotal NPR 150.00'),
    ];
    final blankLines = const [
      ImageParagraph(' '),
      ImageParagraph(' '),
    ];
    final blank = inkBits(await renderLines(blankLines));
    final withText = inkBits(await renderLines(textLines));
    expect(withText, greaterThan(blank + 300),
        reason: 'text glyphs must produce dark dots (pre-fix defect: '
            'paragraphs with no explicit color rasterized to zero ink)');
  });

  test('Devanagari labels rasterize dark dots', () async {
    final bitmap = await renderLines(const [
      ImageParagraph('चिया रसिद ०१२३४५६७८९ धन्यवाद'),
    ]);
    expect(inkBits(bitmap), greaterThan(300),
        reason: 'Devanagari glyphs must leave dark dots in the bitmap');
  });

  test('table header cells never wrap (Amount stays on one line)', () async {
    // A wrapped row is ~2 text lines tall; a single line is ~one.
    for (final cells in const [
      ['Particulars', 'Qty', 'Rate', 'Amount'],
      ['विवरण', 'परि.', 'दर', 'रकम'],
      ['Particulars', 'Qty', 'Rate', '1,500.00'],
    ]) {
      final bitmap = await renderLines([
        ImageColumns(cells, bold: true, sizePx: 24),
      ]);
      // margin 8 + single line ~31 + margin 8 => well under 62; any wrapped
      // cell adds another ~31 dots and exceeds 62.
      expect(bitmap.heightDots, lessThan(62),
          reason: '"$cells" must render every cell on a single line');
      expect(inkBits(bitmap), greaterThan(200),
          reason: 'header row must actually print ink');
    }
  });

  test('Full invoice image layout produces a textful bitmap', () async {
    final data = ReceiptData(
      language: 'ne',
      invoiceNumber: 'INV-000001',
      createdAtMillis: DateTime(2026, 1, 5).millisecondsSinceEpoch,
      org: const {}, // org/feedback fields fall back/are skipped when empty
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
      title: 'बिल',
      invoiceNumber: 'बिल नं.',
      date: 'मिति',
      particulars: 'विवरण',
      customer: 'ग्राहक',
      customerPhone: 'फोन',
      customerAddress: 'ठेगाना',
      qtyLabel: 'मात्रा',
      unitLabel: 'एकाइ',
      rateLabel: 'दर',
      amountLabel: 'रकम',
      subtotal: 'जोड',
      discount: 'छूट',
      tax: 'कर',
      otherCharges: 'अन्य',
      grandTotal: 'कुल',
      paidLabel: 'भुक्तानी',
      dueLabel: 'बाँकी',
      changeLabel: 'उत्ता',
      panCode: 'प्यान:',
      vatCode: 'भ्याट:',
      phoneCode: 'टेल:',
      thankYou: 'धन्यवाद',
    );
    final layout = buildReceiptLayout(
      data: data,
      labels: labels,
      currencySymbol: 'रु.',
      paperWidthMm: 58,
      devanagariNumerals: true,
      dateSystem: DateSystem.ad,
      dateStyle: DateStyle.numeric,
      dateWithTime: false,
      quantityPrecision: 2,
    );
    expect(layout.requiresRaster, isTrue);
    final bitmap = await renderReceiptBitmap(
      lines: layout.imageLines,
      widthDots: layout.widthDots,
    );
    // Baseline: same layout with every text element blanked — rules and dot
    // leaders only. That is what a transparent-fill (no-color) text style
    // produced when text vanished from receipts.
    final blank = inkBits(await renderReceiptBitmap(
      lines: [
        for (final l in layout.imageLines)
          if (l is ImageParagraph)
            ImageParagraph(
              ' ',
              align: l.align,
              bold: l.bold,
              sizePx: l.sizePx,
              spaceBefore: l.spaceBefore,
              spaceAfter: l.spaceAfter,
            )
          else if (l is ImageColumns)
            ImageColumns(
              [for (final _ in l.cells) ' '],
              aligns: l.aligns,
              fractions: l.fractions,
              bold: l.bold,
              sizePx: l.sizePx,
              spaceBefore: l.spaceBefore,
              spaceAfter: l.spaceAfter,
            )
          else if (l is ImageRow)
            ImageRow(
              ' ',
              ' ',
              bold: l.bold,
              sizePx: l.sizePx,
              dotFill: l.dotFill,
              leftFraction: l.leftFraction,
              spaceBefore: l.spaceBefore,
              spaceAfter: l.spaceAfter,
            )
          else
            l,
      ],
      widthDots: layout.widthDots,
    ));
    final full = inkBits(bitmap);
    expect(full, greaterThan(blank * 2),
        reason: 'a real bilingual receipt bitmap must be mostly text, '
            'not just rule/dot lines');
  });

  test('ImageRule renders as a dashed line (alternating ink and gaps)', () async {
    final bitmap = await renderLines(const [ImageRule()]);
    final rowBytes = (bitmap.widthDots + 7) ~/ 8;
    // Count 0->1 and 1->0 horizontal transitions on the first ink row: a
    // dashed line across 384 dots has dozens of dash/gap transitions, whereas
    // a solid line has at most 2.
    var transitions = 0;
    var prevDark = false;
    for (var x = 0; x < bitmap.widthDots; x++) {
      final b = bitmap.packedRows[x >> 3];
      final dark = (b & (0x80 >> (x & 7))) != 0;
      if (dark != prevDark) {
        transitions++;
        prevDark = dark;
      }
    }
    expect(rowBytes, greaterThan(0));
    expect(transitions, greaterThan(40),
        reason: 'ImageRule must render as a dashed line in raster mode');
  });
}
