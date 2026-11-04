/// Pure-Dart ESC/POS byte encoder for the XTKP607UL / compatible thermal
/// printers. Supports:
///  - initialization, alignment, emphasis (bold), double-size text
///  - character-mode printing (ASCII receipts only)
///  - raster image printing via `GS v 0` (any language, incl. Nepali)
///  - feed, partial cut, beep, cash drawer
///
/// NOTE: hardware assumptions are documented in docs/printer_validation.md
/// and must be verified on real hardware (docs/README hardware section).
library;

import 'dart:typed_data';


const esc = 0x1B;
const gs = 0x1D;

/// Receipt styles used by both text and raster paths.
enum ReceiptAlign { left, center, right }

class ReceiptStyle {
  final ReceiptAlign align;
  final bool bold;
  final bool doubleSize; // double width + height
  final int blankLinesAfter;

  const ReceiptStyle({
    this.align = ReceiptAlign.left,
    this.bold = false,
    this.doubleSize = false,
    this.blankLinesAfter = 0,
  });
}

abstract class ReceiptElement {
  const ReceiptElement();
}

class StyleLine extends ReceiptElement {
  final String text;
  final ReceiptStyle style;
  const StyleLine(this.text, {this.style = const ReceiptStyle()});
}

/// Left part and right-aligned part on the same line (dotted layout).
class TwoPartLine extends ReceiptElement {
  final String left;
  final String right;
  final ReceiptStyle style;
  final bool dotFill;
  const TwoPartLine(this.left, this.right, {this.style = const ReceiptStyle(), this.dotFill = false});
}

/// Separator rule across full width.
class RuleLine extends ReceiptElement {
  final String char;
  const RuleLine({this.char = '-'});
}

class FeedLines extends ReceiptElement {
  final int count;
  const FeedLines(this.count);
}

class RasterImage extends ReceiptElement {
  final int widthDots;
  final int heightDots;
  final Uint8List packedRows; // ceil(width/8) bytes per row
  final RasterDensity density;
  const RasterImage({
    required this.widthDots,
    required this.heightDots,
    required this.packedRows,
    this.density = RasterDensity.normal,
  });
}

enum RasterDensity { normal, doubleWidth, doubleHeight, doubleBoth }

extension RasterDensityX on RasterDensity {
  int get mode => switch (this) {
        RasterDensity.normal => 0,
        RasterDensity.doubleWidth => 1,
        RasterDensity.doubleHeight => 2,
        RasterDensity.doubleBoth => 3,
      };
}

/// Serializes receipt elements into raw ESC/POS bytes (character mode for
/// text, GS v 0 raster for images).
Uint8List buildEscPosBytes(
  List<ReceiptElement> elements, {
  required int charCols,
  bool enableCut = true,
  bool enableBeep = false,
  bool enableDrawer = false,
  int feedLinesAtEnd = 5,
  bool smallFont = false,
}) {
  final out = BytesBuilder();
  out.add([esc, 0x40]); // ESC @  init (default font A, no upside-down)
  final blockAlign = smallFont ? ReceiptAlign.center : ReceiptAlign.left;
  for (final e in elements) {
    switch (e) {
      case StyleLine():
        out.add(_emphasis(e.style.bold, e.style.doubleSize, smallFont: smallFont));
        out.add(_align(blockAlign));
        final line = e.style.doubleSize
            ? singleLineAscii(e.text)
            : alignText(e.text, charCols: charCols, align: e.style.align);
        out.add(asciiBytes(line));
        out.add(_lineFeed);
      case TwoPartLine():
        out.add(_emphasis(e.style.bold, e.style.doubleSize, smallFont: smallFont));
        out.add(_align(blockAlign));
        out.add(asciiBytes(twoPartText(e.left, e.right, charCols: charCols, dotFill: e.dotFill)));
        out.add(_lineFeed);
      case ColumnsLine():
        out.add(_emphasis(e.style.bold, e.style.doubleSize, smallFont: smallFont));
        out.add(_align(blockAlign));
        out.add(asciiBytes(
            columnsText(e.cells, charCols: charCols, fractions: e.fractions)));
        out.add(_lineFeed);
      case RuleLine():
        out.add(_emphasis(false, false, smallFont: smallFont));
        out.add(_align(blockAlign));
        out.add(asciiBytes(e.char * charCols));
        out.add(_lineFeed);
      case RasterImage():
        out.add(_align(ReceiptAlign.left));
        out.add(rasterImageBytes(e));
      case FeedLines():
        out.add(List.filled(e.count, 0x0A));
    }
  }
  if (feedLinesAtEnd > 0) {
    out.add(List.filled(feedLinesAtEnd, 0x0A));
  }
  if (enableDrawer) {
    // ESC p m t1 t2 — kick cash drawer pin 2.
    out.add([esc, 0x70, 0x00, 0x19, 0xFA]);
  }
  if (enableBeep) {
    // ESC B n t — beep (common on many Goojprt/compatible firmware builds).
    out.add([esc, 0x42, 0x03, 0x08]);
  }
  if (enableCut) {
    // GS V 0 — full cut (final feed already applied above).
    out.add([gs, 0x56, 0x00]);
  }
  return out.toBytes();
}

/// Maximum vertical dot-rows per `GS v 0` command band.
///
/// Keeping an entire standard receipt (up to 2048 rows ≈ 256 mm) inside a
/// single `GS v 0` command lets the printer drive its stepper motor in one
/// continuous high-speed pass instead of ramping up and stopping between
/// short bands. Very tall receipts still split cleanly at 2048-row boundaries.
const int maxRasterBandRows = 2048;

/// GS v 0 raster: m, xL, xH, yL, yH then packed rows.
///
/// In ESC/POS `GS v 0`, `xL, xH` is the horizontal width in **bytes**
/// (`(widthDots + 7) ~/ 8`), NOT dots, while `yL, yH` is the vertical height
/// in **dots (rows)**. Passing `widthDots` for `xL, xH` makes the printer
/// expect 8x as many bytes and hang inside `GS v 0` waiting for the remaining
/// 7/8ths of the payload (swallowing subsequent print jobs as raw pixel data).
Uint8List rasterImageBytes(
  RasterImage image, {
  int bandRows = maxRasterBandRows,
}) {
  final rowBytes = (image.widthDots + 7) ~/ 8;
  final height = image.heightDots;
  if (rowBytes <= 0 || height <= 0) return Uint8List(0);

  // Data must be exactly rowBytes * height; tolerate padded/short input.
  final totalBytes = rowBytes * height;
  final Uint8List data;
  if (image.packedRows.length == totalBytes) {
    data = image.packedRows;
  } else if (image.packedRows.length > totalBytes) {
    data = Uint8List.sublistView(image.packedRows, 0, totalBytes);
  } else {
    data = Uint8List(totalBytes)
      ..setRange(0, image.packedRows.length, image.packedRows);
  }

  final step = bandRows <= 0 ? height : bandRows;
  final out = BytesBuilder();
  for (var y = 0; y < height; y += step) {
    final rows = (y + step <= height) ? step : (height - y);
    out.add([gs, 0x76, 0x30, image.density.mode]);
    out.add([rowBytes & 0xFF, (rowBytes >> 8) & 0xFF]);
    out.add([rows & 0xFF, (rows >> 8) & 0xFF]);
    final start = y * rowBytes;
    final end = start + rows * rowBytes;
    out.add(Uint8List.sublistView(data, start, end));
  }
  return out.toBytes();
}

List<int> get _lineFeed => [0x0A];

List<int> _align(ReceiptAlign a) => switch (a) {
      ReceiptAlign.left => [esc, 0x61, 0x00],
      ReceiptAlign.center => [esc, 0x61, 0x01],
      ReceiptAlign.right => [esc, 0x61, 0x02],
    };

/// ESC ! n — select print mode(s). b0 = Font B (small 9x17), b3 = bold,
/// b4 = double height, b5 = double width.
List<int> _emphasis(bool bold, bool doubleSize, {bool smallFont = true}) {
  var mask = (smallFont && !doubleSize) ? 0x01 : 0x00;
  if (bold) mask |= 0x08;
  if (doubleSize) mask |= 0x30;
  return [esc, 0x21, mask];
}

/// Pads [text] to [charCols] characters according to [align] so every
/// character-mode line shares the exact same column width and center axis.
String alignText(
  String text, {
  required int charCols,
  required ReceiptAlign align,
}) {
  final t = singleLineAscii(text);
  if (t.length >= charCols) return t;
  switch (align) {
    case ReceiptAlign.left:
      return t.padRight(charCols);
    case ReceiptAlign.center:
      final left = (charCols - t.length) ~/ 2;
      return (' ' * left + t).padRight(charCols);
    case ReceiptAlign.right:
      return t.padLeft(charCols);
  }
}

/// Encodes text to bytes; in character mode we require ASCII only and strip
/// combiners the printer cannot render (the raster engine is used instead).
List<int> utfPrintable(String text, {required int charCols, bool forceSingleWidth = false}) {
  final t = singleLineAscii(text);
  return asciiBytes(t);
}

String singleLineAscii(String text) =>
    text.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');

/// Left/right two-part line laid out to exactly [charCols] characters.
String twoPartText(String left, String right, {required int charCols, bool dotFill = false}) {
  final l = singleLineAscii(left);
  final r = singleLineAscii(right);
  if (l.length + r.length >= charCols) {
    // Wrap-left behavior: shrink left, keep right intact with a 1-space gap.
    final keep = (charCols - r.length - 1).clamp(1, charCols);
    final clippedLeft = l.substring(0, keep.clamp(0, l.length));
    final spaces = (charCols - clippedLeft.length - r.length).clamp(1, charCols);
    return clippedLeft + ' ' * spaces + r;
  }
  final gap = charCols - l.length - r.length;
  if (dotFill) {
    return l + '.' * gap + r;
  }
  return l + ' ' * gap + r;
}

String rightPad(String sep, String right, int spaces, int total) => ' ' * spaces + right;

/// Printable columns for a paper width (character mode uses ~0.6 mm/char).
int charColumnsFor(int paperWidthMm) {
  if (paperWidthMm <= 58) return 32;
  if (paperWidthMm <= 62) return 40;
  return 48;
}

/// Column shares of the printable width for the items table
/// (Particulars, Qty, Rate, Amount), used by both engines. Amount gets the
/// largest right column so common values like "1,500.00" fit without
/// wrapping; the raster engine additionally right-anchors those cells so
/// oversized values overflow the gap instead of breaking mid-number.
const List<double> receiptTableFractions = [0.42, 0.15, 0.19, 0.24];

/// A tabular row rendered in fixed-width character columns: the first cell
/// is left-aligned, every later cell right-aligned inside its own column.
class ColumnsLine extends ReceiptElement {
  final List<String> cells;
  final List<double> fractions;
  final ReceiptStyle style;
  const ColumnsLine(
    this.cells, {
    this.fractions = receiptTableFractions,
    this.style = const ReceiptStyle(),
  });
}

/// Column widths for [cells] over [charCols] columns. Right-aligned columns
/// (index > 0) always fully contain their text — they grow, giving back
/// slack among the other right columns first; column 0 absorbs the rest.
List<int> tableColumnWidths(
  List<String> cells, {
  required int charCols,
  required List<double> fractions,
}) {
  final n = cells.length;
  final widths = List<int>.generate(
      n, (i) => (charCols * fractions[i]).floor().clamp(1, charCols));
  for (var i = n - 1; i >= 1; i--) {
    // +1 reserves a minimum one-character gap between adjacent columns.
    final need = singleLineAscii(cells[i]).length + 1;
    if (need > widths[i]) widths[i] = need;
  }
  var overflow = widths.fold<int>(0, (a, b) => a + b) - charCols;
  while (overflow > 0) {
    var best = -1;
    var bestSlack = 0;
    for (var i = n - 1; i >= 1; i--) {
      final slack = widths[i] - (singleLineAscii(cells[i]).length + 1);
      if (slack > bestSlack) {
        bestSlack = slack;
        best = i;
      }
    }
    if (best < 0 || bestSlack == 0) break;
    final take = bestSlack < overflow ? bestSlack : overflow;
    widths[best] -= take;
    overflow -= take;
  }
  widths[0] =
      (charCols - widths.skip(1).fold<int>(0, (a, b) => a + b)).clamp(1, charCols);
  return widths;
}

/// Serializes a tabular row into one fixed-width ASCII line. Column 0 is
/// left-aligned (truncated on overflow), later columns right-aligned and
/// never truncated.
String columnsText(
  List<String> cells, {
  required int charCols,
  List<double> fractions = receiptTableFractions,
}) {
  final widths =
      tableColumnWidths(cells, charCols: charCols, fractions: fractions);
  final buf = StringBuffer();
  for (var i = 0; i < cells.length; i++) {
    final t = singleLineAscii(cells[i]);
    if (i == 0) {
      buf.write(t.length > widths[i]
          ? t.substring(0, widths[i])
          : t.padRight(widths[i]));
    } else {
      // Leading gap space + content right-anchored in (width-1): column
      // boundaries are guarantees of >= 1 blank between adjacent cells.
      buf.write(' ');
      buf.write(t.padLeft(widths[i] - 1));
    }
  }
  return buf.toString();
}

/// Shared dot-width computation: 8 dots/mm at 203 dpi, minus edge margin.
/// Printable width in head dots for a configured paper roll width.
/// Thermal heads are fixed devices: 8 dots/mm (203 dpi) with a printable band
/// that does not cover the full roll — 58 mm-class printers print ≈48 mm
/// (384 dots), 80 mm-class ≈72 mm (576 dots). Sending a bitmap wider than the
/// head makes the printer squash or clip it, which reads as a mushy, lossy-
/// JPEG-like receipt. Mirrors the `charColumnsFor` class table (32/48 cols
/// × 12 dots/char = 384/576) — keep both in sync.
int dotsForWidthMm(int mm) => mm <= 62 ? 384 : 576;

/// True when every character can be printed in native ESC/POS text mode.
bool isAsciiOnly(String text) => RegExp(r'^[\x20-\x7E\n]*$').hasMatch(text);

List<int> asciiBytes(String s) => s.codeUnits;
