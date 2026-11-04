/// Receipt layout engine: converts an invoice's data and design settings
/// into a layout shared by both output paths:
///  - ESC/POS character mode (pure-ASCII English receipts), and
///  - raster image mode (required for reliable Devanagari).
///
/// All labels come from generated localizations for the invoice language —
/// nothing user-visible is hardcoded here.
library;

import '../../core/formatting/dates.dart';
import '../../core/formatting/money.dart';
import '../models/invoice.dart';
import '../models/unit.dart';
import 'escpos.dart';

/// Everything needed to render one receipt.
class ReceiptData {
  /// 'en' | 'ne' — resolved invoice language (never 'follow').
  final String language;
  final String invoiceNumber;
  final int createdAtMillis;
  final Map<String, Object?> org;
  final Map<String, Object?> receipt; // decoded receipt settings snapshot
  final List<ReceiptItemData> items;
  final BillTotals totals;
  final CustomerInfo? customer;
  final String? otherChargesNote;
  final String? notes;

  const ReceiptData({
    required this.language,
    required this.invoiceNumber,
    required this.createdAtMillis,
    required this.org,
    required this.receipt,
    required this.items,
    required this.totals,
    required this.customer,
    this.otherChargesNote,
    this.notes,
  });

  bool get nepali => language == 'ne';
}

class ReceiptItemData {
  final int? productId;
  final String nameEn;
  final String nameNe;
  final String unitEn;
  final String unitNe;
  final int quantityMilli;
  final int ratePaisa;
  final int lineTotalPaisa;

  const ReceiptItemData({
    required this.productId,
    required this.nameEn,
    required this.nameNe,
    required this.unitEn,
    required this.unitNe,
    required this.quantityMilli,
    required this.ratePaisa,
    required this.lineTotalPaisa,
  });

  /// Defined fallback: prefer requested language; else the other one.
  String nameFor(bool nepali) {
    final primary = nepali ? nameNe : nameEn;
    if (primary.trim().isNotEmpty) return primary;
    return (nepali ? nameEn : nameNe).trim();
  }

  String unitFor(bool nepali) {
    final primary = nepali ? unitNe : unitEn;
    final secondary = nepali ? unitEn : unitNe;
    final raw = primary.trim().isNotEmpty ? primary.trim() : secondary.trim();
    if (raw.isEmpty) return '';
    return shortUnit(raw, nepali: nepali);
  }
}

/// Labels resolved from the generated localizations for the invoice
/// language (never hardcoded strings).
class ReceiptLabels {
  final String title;
  final String invoiceNumber;
  final String date;
  final String particulars;
  final String customer;
  final String customerPhone;
  final String customerAddress;
  final String qtyLabel;
  final String unitLabel;
  final String rateLabel;
  final String amountLabel;
  final String subtotal;
  final String discount;
  final String tax;
  final String otherCharges;
  final String grandTotal;
  final String paidLabel;
  final String dueLabel;
  final String changeLabel;
  final String panCode;
  final String vatCode;
  final String phoneCode;
  final String thankYou;

  const ReceiptLabels({
    required this.title,
    required this.invoiceNumber,
    required this.date,
    required this.particulars,
    required this.customer,
    required this.customerPhone,
    required this.customerAddress,
    required this.qtyLabel,
    required this.unitLabel,
    required this.rateLabel,
    required this.amountLabel,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.otherCharges,
    required this.grandTotal,
    required this.paidLabel,
    required this.dueLabel,
    required this.changeLabel,
    required this.panCode,
    required this.vatCode,
    required this.phoneCode,
    required this.thankYou,
  });
}

/// Output built by the layout engine.
class ReceiptLayoutResult {
  /// Character-mode ESC/POS elements (ASCII receipts).
  final List<ReceiptElement> textElements;

  /// Dot-space layout for raster rendering.
  final List<ImageLine> imageLines;
  final int widthDots;

  /// True when the receipt should be printed as a bitmap (auto mode).
  final bool requiresRaster;

  const ReceiptLayoutResult({
    required this.textElements,
    required this.imageLines,
    required this.widthDots,
    required this.requiresRaster,
  });
}

/// One drawable unit in dot space.
abstract class ImageLine {
  const ImageLine({this.spaceBefore = 0, this.spaceAfter = 0});
  final int spaceBefore;
  final int spaceAfter;
}

class ImageParagraph extends ImageLine {
  final String text;
  final ReceiptAlign align;
  final bool bold;

  /// Font size in dots (22 ≈ standard body text at 203 dpi).
  final int sizePx;

  const ImageParagraph(
    this.text, {
    this.align = ReceiptAlign.left,
    this.bold = false,
    this.sizePx = 22,
    super.spaceBefore,
    super.spaceAfter,
  });
}

class ImageRow extends ImageLine {
  final String left;
  final String right;
  final bool bold;
  final int sizePx;
  final bool dotFill;

  /// Fraction of the row width available for the left paragraph.
  final double leftFraction;

  const ImageRow(
    this.left,
    this.right, {
    this.bold = false,
    this.sizePx = 22,
    this.dotFill = false,
    this.leftFraction = 0.62,
    super.spaceBefore,
    super.spaceAfter,
  });
}

/// One tabular row in dot space: fixed-width columns (fractions of the
/// printable width), first column left-aligned, the rest right-aligned.
class ImageColumns extends ImageLine {
  final List<String> cells;
  final List<ReceiptAlign> aligns;
  final List<double> fractions;
  final bool bold;
  final int sizePx;

  const ImageColumns(
    this.cells, {
    this.aligns = const [
      ReceiptAlign.left,
      ReceiptAlign.right,
      ReceiptAlign.right,
      ReceiptAlign.right,
    ],
    this.fractions = receiptTableFractions,
    this.bold = false,
    this.sizePx = 22,
    super.spaceBefore,
    super.spaceAfter,
  });
}

// Default spacing is intentionally overridden here; super parameters are
// not applicable because the values differ from the inherited defaults.
// ignore: use_super_parameters
class ImageRule extends ImageLine {
  // ignore: use_super_parameters
  const ImageRule({int spaceBefore = 1, int spaceAfter = 1})
      : super(spaceBefore: spaceBefore, spaceAfter: spaceAfter);
}

/// Builds the complete receipt layout for a paper width.
ReceiptLayoutResult buildReceiptLayout({
  required ReceiptData data,
  required ReceiptLabels labels,
  required String currencySymbol,
  required int paperWidthMm,
  required bool devanagariNumerals,
  required DateSystem dateSystem,
  required DateStyle dateStyle,
  required bool dateWithTime,
  required int quantityPrecision,
}) {
  final nepali = data.nepali;
  final widthDots = dotsForWidthMm(paperWidthMm);

  // All money/quantities display either Devanagari or Western digits.
  final bool devDigits = devanagariNumerals || nepali;

  String money(int paisa, {bool withSymbol = true}) {
    final text = formatScaled(
      paisa,
      scale: paisaPerNPR,
      decimals: 2,
      devanagari: devDigits,
    );
    if (!withSymbol) return text;
    return '$currencySymbol $text';
  }

  String qty(int quantityMilli, {String unit = ''}) {
    final text = formatScaled(
      quantityMilli,
      scale: qtyScale,
      decimals: quantityPrecision.clamp(0, 3),
      devanagari: devDigits,
    );
    return unit.isEmpty ? text : '$text $unit';
  }

  String pct(int hundredths) {
    final s = formatScaled(hundredths, scale: percentScale, decimals: 2, devanagari: devDigits);
    return devDigits ? '$s%' : '$s%';
  }

  final org = data.org;
  final rc = data.receipt;
  final bool showAddress = (rc['show_address'] as int? ?? 1) != 0;
  final bool showPhone = (rc['show_phone'] as int? ?? 1) != 0;
  final bool showEmail = (rc['show_email'] as int? ?? 0) != 0;
  final bool showWebsite = (rc['show_website'] as int? ?? 0) != 0;
  final bool showPanVat = (rc['show_pan_vat'] as int? ?? 1) != 0;
  final bool showCustomer = (rc['show_customer'] as int? ?? 1) != 0;
  final bool showPayment = (rc['show_payment'] as int? ?? 1) != 0;
  final headerAlign = (rc['header_align'] as String? ?? 'center') == 'left'
      ? ReceiptAlign.left
      : ReceiptAlign.center;

  // Picks the requested-language version of a bilingual org field with a
  // defined fallback to the other language.
  String orgField(String enKey, String neKey) {
    final en = (org[enKey] as String? ?? '').trim();
    final ne = (org[neKey] as String? ?? '').trim();
    final primary = nepali ? ne : en;
    if (primary.isNotEmpty) return primary;
    return nepali ? en : ne;
  }

  String msg(String enKey, String neKey) {
    final en = (rc[enKey] as String? ?? '').trim();
    final ne = (rc[neKey] as String? ?? '').trim();
    final primary = nepali ? ne : en;
    if (primary.isNotEmpty) return primary;
    return nepali ? en : ne;
  }

  // ---------- Dot-space layout (bitmap raster) ----------
  final img = <ImageLine>[];

  void p(
    String text, {
    ReceiptAlign align = ReceiptAlign.left,
    bool bold = false,
    int sizePx = 22,
    int sb = 0,
    int sa = 0,
  }) {
    if (text.trim().isEmpty) return;
    img.add(ImageParagraph(text, align: align, bold: bold, sizePx: sizePx,
        spaceBefore: sb, spaceAfter: sa));
  }

  void row(
    String left,
    String right, {
    bool bold = false,
    int sizePx = 22,
    bool dotFill = false,
    int sb = 0,
    int sa = 0,
  }) {
    if (left.isEmpty && right.isEmpty) return;
    img.add(
      ImageRow(
        left,
        right,
        bold: bold,
        sizePx: sizePx,
        dotFill: dotFill,
        spaceBefore: sb,
        spaceAfter: sa,
      ),
    );
  }

  void rule({int before = 1, int after = 1}) =>
      img.add(ImageRule(spaceBefore: before, spaceAfter: after));

  /// Fixed-width columns row for the items table.
  void imageColumns(
    List<String> cells, {
    bool bold = false,
    int sizePx = 22,
    int sb = 0,
    int sa = 0,
  }) {
    if (cells.every((c) => c.trim().isEmpty)) return;
    img.add(ImageColumns(
      cells,
      bold: bold,
      sizePx: sizePx,
      spaceBefore: sb,
      spaceAfter: sa,
    ));
  }

  final welcome = msg('welcome_en', 'welcome_ne');
  final orgName = orgField('name_en', 'name_ne');
  if (orgName.isNotEmpty) p(orgName, align: headerAlign, bold: true, sizePx: 26);
  if (showAddress) {
    final addr = orgField('address_en', 'address_ne');
    if (addr.isNotEmpty) {
      for (final line in addr.split('\n')) {
        final l = line.trim();
        if (l.isEmpty) continue;
        p(l, align: headerAlign, sizePx: 22);
      }
    }
    final custom = orgField('custom_info_en', 'custom_info_ne');
    if (custom.isNotEmpty) p(custom, align: headerAlign, sizePx: 20);
  }
  if (showPhone) {
    final parts = <String>[];
    for (final k in ['phone', 'alternative_phone']) {
      final v = (org[k] as String? ?? '').trim();
      if (v.isNotEmpty) parts.add(v);
    }
    if (parts.isNotEmpty) p('${labels.phoneCode} ${parts.join(' / ')}', align: headerAlign, sizePx: 22);
  }
  if (showEmail) {
    final em = (org['email'] as String? ?? '').trim();
    if (em.isNotEmpty) p(em, align: headerAlign, sizePx: 22);
  }
  if (showWebsite) {
    final w = (org['website'] as String? ?? '').trim();
    if (w.isNotEmpty) p(w, align: headerAlign, sizePx: 22);
  }
  if (showPanVat) {
    final parts = <String>[];
    final pan = (org['pan_number'] as String? ?? '').trim();
    final vat = (org['vat_number'] as String? ?? '').trim();
    if (pan.isNotEmpty) {
      parts.add('${labels.panCode} ${devDigits ? toDevanagariDigits(pan) : pan}');
    }
    if (vat.isNotEmpty) {
      parts.add('${labels.vatCode} ${devDigits ? toDevanagariDigits(vat) : vat}');
    }
    if (parts.isNotEmpty) p(parts.join('   '), align: headerAlign, sizePx: 22);
  }
  final reg = (org['registration_number'] as String? ?? '').trim();
  if (showWebsite && reg.isNotEmpty) p(reg, align: headerAlign, sizePx: 20);
  if (welcome.isNotEmpty) p(welcome, align: headerAlign, sizePx: 22);
  p(labels.title, align: headerAlign, bold: true, sizePx: 24, sb: 2, sa: 2);

  // Meta
  p('${labels.invoiceNumber}: ${data.invoiceNumber}');
  final dateText = formatReceiptDateMillis(
    data.createdAtMillis,
    system: dateSystem,
    style: dateStyle,
    withTime: dateWithTime,
    nepaliNames: nepali,
    devanagariNumerals: devDigits,
  );
  p('${labels.date}: $dateText');
  if (showCustomer && data.customer != null && !data.customer!.isEmpty) {
    final c = data.customer!;
    if (c.name.isNotEmpty) p('${labels.customer}: ${c.name}');
    if (c.phone.isNotEmpty) p('${labels.customerPhone}: ${c.phone}');
    if (c.address.isNotEmpty) p('${labels.customerAddress}: ${c.address}');
  }
  rule();

  // Items as a table: Particulars | Qty | Rate | Amount.
  imageColumns(
    [labels.particulars, labels.qtyLabel, labels.rateLabel, labels.amountLabel],
    bold: true,
    sizePx: 22,
  );
  for (final it in data.items) {
    imageColumns([
      it.nameFor(nepali),
      qty(it.quantityMilli, unit: it.unitFor(nepali)),
      money(it.ratePaisa, withSymbol: false),
      money(it.lineTotalPaisa, withSymbol: false),
    ], sizePx: 22);
  }
  rule();

  // Totals
  row(labels.subtotal, money(data.totals.subtotalPaisa), sizePx: 22);
  if (data.totals.discountAmount > 0) {
    final left = data.totals.discountType == DiscountType.percent
        ? '${labels.discount} (${pct(data.totals.discountValue)})'
        : labels.discount;
    row(left, '- ${money(data.totals.discountAmount, withSymbol: false)}', sizePx: 22);
  }
  if (data.totals.taxAmount > 0) {
    final left = data.totals.taxRate > 0
        ? '${labels.tax} (${pct(data.totals.taxRate)})'
        : labels.tax;
    row(left, money(data.totals.taxAmount), sizePx: 22);
  }
  if (data.totals.otherCharges > 0) {
    final note = (data.otherChargesNote ?? '').trim();
    row(note.isEmpty ? labels.otherCharges : note, money(data.totals.otherCharges), sizePx: 22);
  }
  row(labels.grandTotal, money(data.totals.grandTotal), bold: true, sizePx: 24);
  if (showPayment) {
    // Paid amount and change are printed; the balance (due) row is
    // intentionally omitted from receipts.
    if (data.totals.amountPaid > 0) {
      row(labels.paidLabel, money(data.totals.amountPaid), sizePx: 22);
      if (data.totals.balanceDue < 0) {
        row(labels.changeLabel, money(-data.totals.balanceDue), sizePx: 22);
      }
    }
  }
  final notes = (data.notes ?? '').trim();
  if (notes.isNotEmpty) p(notes, sizePx: 20);

  // Footer
  img.add(const ImageRule(spaceBefore: 1, spaceAfter: 1));
  final footerLines = <String>[];
  void footer(String enKey, String neKey) {
    final m = msg(enKey, neKey);
    if (m.isNotEmpty) footerLines.add(m);
  }

  footer('policy_en', 'policy_ne');
  footer('terms_en', 'terms_ne');
  footer('promo_en', 'promo_ne');
  footer('extra_en', 'extra_ne');
  final thank = msg('thank_en', 'thank_ne');
  p(
    thank.isNotEmpty ? thank : labels.thankYou,
    align: ReceiptAlign.center,
    bold: true,
    sizePx: 22,
  );
  for (final f in footerLines) {
    p(f, align: ReceiptAlign.center, sizePx: 20);
  }

  // ---------- Character-mode layout (ASCII-only path) ----------
  final txt = <ReceiptElement>[];
  final asciiSeen = <String>[]; // raw strings that will hit text mode
  void tAddText(String raw, {bool bold = false, bool doubleSize = false, ReceiptAlign align = ReceiptAlign.left}) {
    asciiSeen.add(raw);
    txt.add(StyleLine(raw, style: ReceiptStyle(bold: bold, doubleSize: doubleSize, align: align)));
  }

  void tAddRow(String rawLeft, String rawRight, {bool dotFill = false, bool bold = false, bool doubleSize = false}) {
    asciiSeen.add(rawLeft);
    asciiSeen.add(rawRight);
    txt.add(
      TwoPartLine(rawLeft, rawRight, dotFill: dotFill, style: ReceiptStyle(bold: bold, doubleSize: doubleSize)),
    );
  }

  /// Tabular columns row for the items table in character mode.
  void tAddColumns(List<String> cells, {bool bold = false}) {
    asciiSeen.addAll(cells);
    txt.add(ColumnsLine(cells, style: ReceiptStyle(bold: bold)));
  }

  if (orgName.isNotEmpty) tAddText(orgName, bold: true, align: headerAlign);
  if (showAddress) {
    final addr = orgField('address_en', 'address_ne');
    if (addr.isNotEmpty) {
      asciiSeen.add(addr);
      txt.add(StyleLine(addr, style: ReceiptStyle(align: headerAlign)));
    }
    final custom = orgField('custom_info_en', 'custom_info_ne');
    if (custom.isNotEmpty) {
      asciiSeen.add(custom);
      txt.add(StyleLine(custom, style: ReceiptStyle(align: headerAlign)));
    }
  }
  if (showPhone) {
    final parts = <String>[];
    for (final k in ['phone', 'alternative_phone']) {
      final v = (org[k] as String? ?? '').trim();
      if (v.isNotEmpty) parts.add(v);
    }
    if (parts.isNotEmpty) tAddText('${labels.phoneCode} ${parts.join(' / ')}', align: headerAlign);
  }
  if (showEmail) {
    final em = (org['email'] as String? ?? '').trim();
    if (em.isNotEmpty) tAddText(em, align: headerAlign);
  }
  if (showWebsite) {
    final w = (org['website'] as String? ?? '').trim();
    if (w.isNotEmpty) tAddText(w, align: headerAlign);
  }
  if (showPanVat) {
    final parts = <String>[];
    final pan = (org['pan_number'] as String? ?? '').trim();
    final vat = (org['vat_number'] as String? ?? '').trim();
    if (pan.isNotEmpty) parts.add('${labels.panCode} $pan');
    if (vat.isNotEmpty) parts.add('${labels.vatCode} $vat');
    if (parts.isNotEmpty) tAddText(parts.join('   '), align: headerAlign);
  }
  if (welcome.isNotEmpty) tAddText(welcome, align: headerAlign);
  tAddText(labels.title, bold: true, align: headerAlign);
  tAddText('${labels.invoiceNumber}: ${data.invoiceNumber}');
  tAddText('${labels.date}: $dateText');
  if (showCustomer && data.customer != null && !data.customer!.isEmpty) {
    final c = data.customer!;
    if (c.name.isNotEmpty) tAddText('${labels.customer}: ${c.name}');
    if (c.phone.isNotEmpty) tAddText('${labels.customerPhone}: ${c.phone}');
    if (c.address.isNotEmpty) tAddText('${labels.customerAddress}: ${c.address}');
  }
  txt.add(const RuleLine());
  tAddColumns(
    [labels.particulars, labels.qtyLabel, labels.rateLabel, labels.amountLabel],
    bold: true,
  );
  // Character-mode column widths are decided per row with the same math the
  // serializer uses (tableColumnWidths), so the name-fit decision below can
  // never disagree with the printed layout.
  final textCols = charColumnsFor(paperWidthMm);
  for (final it in data.items) {
    final name = it.nameFor(false);
    final unit = it.unitFor(false);
    final rawQty =
        formatScaled(it.quantityMilli, scale: qtyScale, decimals: quantityPrecision.clamp(0, 3));
    final qtyCell = unit.isEmpty ? rawQty : '$rawQty $unit';
    final rateCell = formatScaled(it.ratePaisa, scale: paisaPerNPR, decimals: 2);
    final amountCell = formatScaled(it.lineTotalPaisa, scale: paisaPerNPR, decimals: 2);
    final widths = tableColumnWidths(
      [name, qtyCell, rateCell, amountCell],
      charCols: textCols,
      fractions: receiptTableFractions,
    );
    final fits = singleLineAscii(name).length <= widths.first;
    if (!fits) tAddText(name);
    tAddColumns([
      fits ? name : '',
      qtyCell,
      rateCell,
      amountCell,
    ]);
  }
  txt.add(const RuleLine());
  tAddRow(labels.subtotal, money(data.totals.subtotalPaisa));
  if (data.totals.discountAmount > 0) {
    final left = data.totals.discountType == DiscountType.percent
        ? '${labels.discount} (${pct(data.totals.discountValue)})'
        : labels.discount;
    tAddRow(left, '- ${money(data.totals.discountAmount, withSymbol: false)}');
  }
  if (data.totals.taxAmount > 0) {
    final left = data.totals.taxRate > 0 ? '${labels.tax} (${pct(data.totals.taxRate)})' : labels.tax;
    tAddRow(left, money(data.totals.taxAmount));
  }
  if (data.totals.otherCharges > 0) {
    final note = (data.otherChargesNote ?? '').trim();
    tAddRow(note.isEmpty ? labels.otherCharges : note, money(data.totals.otherCharges));
  }
  tAddRow(labels.grandTotal, money(data.totals.grandTotal), bold: true);
  if (showPayment && data.totals.amountPaid > 0) {
    // Paid amount and change are printed; the balance (due) row is
    // intentionally omitted from receipts.
    tAddRow(labels.paidLabel, money(data.totals.amountPaid));
    if (data.totals.balanceDue < 0) {
      tAddRow(labels.changeLabel, money(-data.totals.balanceDue));
    }
  }
  if (notes.isNotEmpty) tAddText(notes);
  txt.add(const RuleLine());
  final tThank = msg('thank_en', 'thank_ne');
  tAddText(tThank.isNotEmpty ? tThank : labels.thankYou, bold: true, align: ReceiptAlign.center);
  for (final f in footerLines) {
    tAddText(f, align: ReceiptAlign.center);
  }

  // Raster needed when: Nepali labels/numerals are engaged, or any raw text
  // string that would reach the text path contains non-ASCII characters.
  final requiresRaster =
      nepali || devanagariNumerals || asciiSeen.any((s) => !isAsciiOnly(s));

  return ReceiptLayoutResult(
    textElements: txt,
    imageLines: img,
    widthDots: widthDots,
    requiresRaster: requiresRaster,
  );
}

String asciiSanitize(String s) => s.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
