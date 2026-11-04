/// Raster renderer: turns ImageLine layouts into a 1-bit monochrome bitmap
/// using Flutter's text shaping (HarfBuzz), guaranteeing correct Devanagari
/// conjuncts, matras and ordering — this is how Nepali receipts print
/// reliably on ESC/POS-class thermal printers.
///
/// Output: `Uint8List` with ceil(width/8) packed bytes per row,
/// MSB = leftmost dot, black = 1 — exactly the `GS v 0` raster format.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'escpos.dart';
import 'receipt_layout.dart';

/// Latin font family for receipts; Devanagari is reached through
/// fontFamilyFallback, letting the engine pick the right script per glyph
/// while keeping shaping intact.
const receiptLatinFont = 'NotoSans';
const receiptFontFallback = <String>['NotoSansDevanagari'];

class RasterBitmap {
  final Uint8List packedRows;
  final int widthDots;
  final int heightDots;

  const RasterBitmap(this.packedRows, this.widthDots, this.heightDots);
}

/// Renders [lines] into a 1-bit bitmap [widthDots] wide.
/// [logoBytes] (PNG/JPEG) is drawn centered at the top when provided.
/// [textScale] scales every paragraph size (receipt `text_size` setting).
Future<RasterBitmap> renderReceiptBitmap({
  required List<ImageLine> lines,
  required int widthDots,
  int marginDots = 8,
  Uint8List? logoBytes,
  double textScale = 1.0,
}) async {
  final usable = math.max(1, widthDots - marginDots * 2);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // 2x supersampling: raster ink is 1-bit, so every dot must commit to black
  // or white. Rendering at double resolution and box-averaging ink coverage
  // back to 1x keeps glyph edges clean instead of letting the anti-aliased
  // fringe flip dot-by-dot (the ragged, smeary "lossy image" look).
  const ss = 2;
  canvas.scale(ss.toDouble(), ss.toDouble());

  double cursor = 0.0;

  ui.Paragraph measure(String text, ReceiptAlign align, bool bold, int sizeRaw, double wrapWidth) {
    final sizePx = (sizeRaw * textScale).round().clamp(6, 96);
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: sizePx.toDouble(),
        fontFamily: receiptLatinFont,
        fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
        textAlign: switch (align) {
          ReceiptAlign.left => ui.TextAlign.left,
          ReceiptAlign.center => ui.TextAlign.center,
          ReceiptAlign.right => ui.TextAlign.right,
        },
        height: 1.15, // compact line height while keeping Devanagari matras safe
      ),
    );
    builder.pushStyle(
      ui.TextStyle(
        // Explicit fill is required: with no color (and no foreground paint)
        // the engine draws glyphs with a transparent fill — they occupy
        // layout height but produce zero dark pixels, leaving the receipt
        // blank except for the rule/dot leaders. Thermal output depends on
        // this being black (see the luminance threshold below).
        color: const ui.Color(0xFF000000),
        fontFamily: receiptLatinFont,
        fontFamilyFallback: receiptFontFallback,
        fontSize: sizePx.toDouble(),
        fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
      ),
    );
    builder.addText(text);
    builder.pop();
    final para = builder.build();
    para.layout(ui.ParagraphConstraints(width: wrapWidth));
    return para;
  }

  // Decode + draw the organization logo (best-effort).
  if (logoBytes != null && logoBytes.isNotEmpty) {
    try {
      final codec =
          await ui.instantiateImageCodec(logoBytes, targetWidth: 220 * ss);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final x = marginDots + (usable - image.width) / 2;
      canvas.drawImage(image, ui.Offset(x, cursor), ui.Paint());
      cursor += image.height.toDouble() + 2;
      codec.dispose();
    } catch (_) {
      // Receipts still print when the logo cannot be decoded.
    }
  }

  for (final line in lines) {
    if (line.spaceBefore > 0) cursor += line.spaceBefore;
    switch (line) {
      case ImageParagraph():
        final para = measure(line.text, line.align, line.bold, line.sizePx, usable * 1.0);
        if (line.text.trim().isNotEmpty) {
          canvas.drawParagraph(para, ui.Offset(marginDots.toDouble(), cursor));
        }
        cursor += para.height;
        break;
      case ImageRow():
        final rightW = usable * (1 - line.leftFraction);
        final leftW = usable * line.leftFraction;
        final right = measure(line.right, ReceiptAlign.right, line.bold, line.sizePx, rightW);
        final left = measure(line.left, ReceiptAlign.left, line.bold, line.sizePx, leftW);
        final rowHeight = math.max(left.height, right.height);
        final yTop = cursor;
        if (line.dotFill) {
          final dotPaint = ui.Paint()..color = const ui.Color(0xFF000000);
          final leftWidth = line.left.isEmpty ? 0.0 : math.min(leftW, left.longestLine + 6);
          final rightStart = marginDots + usable - right.longestLine;
          final yMid = yTop + rowHeight / 2;
          for (double dx = marginDots + leftWidth; dx + 2 < rightStart; dx += 5) {
            canvas.drawPoints(
              ui.PointMode.points,
              [ui.Offset(dx, yMid), ui.Offset(dx + 1.5, yMid)],
              dotPaint,
            );
          }
        }
        if (line.left.trim().isNotEmpty) {
          canvas.drawParagraph(left, ui.Offset(marginDots.toDouble(), yTop));
        }
        if (line.right.trim().isNotEmpty) {
          canvas.drawParagraph(right, ui.Offset(marginDots + usable - rightW, yTop));
        }
        cursor += rowHeight;
        break;
      case ImageColumns():
        // Column boundaries from the shared fractions.
        final starts = <double>[];
        final widths = <double>[];
        var acc = marginDots.toDouble();
        for (final f in line.fractions) {
          final w = math.max(6.0, usable * f);
          starts.add(acc);
          widths.add(w);
          acc += w;
        }
        // Measure everything first. Right-aligned cells are laid out on the
        // full row width (numbers and short labels are single lines there)
        // and then drawn right-anchored to the column's right edge, so they
        // can never wrap mid-value (e.g. the header "Amount"); oversized
        // values overflow into the gap on their left instead. Left cells
        // wrap inside their own column as before.
        final paras = <ui.Paragraph>[];
        final xs = <double>[];
        for (var i = 0; i < line.cells.length; i++) {
          final rightCell = line.aligns[i] == ReceiptAlign.right;
          final ui.Paragraph para;
          final double x;
          if (rightCell) {
            para = measure(line.cells[i], ReceiptAlign.left, line.bold,
                line.sizePx, usable.toDouble());
            final anchor = starts[i] + widths[i] - para.longestLine;
            x = math.max(marginDots.toDouble(), anchor);
          } else {
            para = measure(line.cells[i], line.aligns[i], line.bold,
                line.sizePx, widths[i]);
            x = starts[i];
          }
          paras.add(para);
          xs.add(x);
        }
        var tableRowHeight = 0.0;
        for (final para in paras) {
          if (para.height > tableRowHeight) tableRowHeight = para.height;
        }
        for (var i = 0; i < paras.length; i++) {
          if (line.cells[i].trim().isNotEmpty) {
            canvas.drawParagraph(paras[i], ui.Offset(xs[i], cursor));
          }
        }
        cursor += tableRowHeight;
        break;
      case ImageRule():
        final paint = ui.Paint()
          ..color = const ui.Color(0xFF000000)
          ..strokeWidth = 2.0;
        final yMid = cursor + 3.0;
        const dashWidth = 7.0;
        const dashGap = 5.0;
        final endX = (marginDots + usable).toDouble();
        var x = marginDots.toDouble();
        while (x < endX) {
          final x2 = math.min(x + dashWidth, endX);
          canvas.drawLine(ui.Offset(x, yMid), ui.Offset(x2, yMid), paint);
          x += dashWidth + dashGap;
        }
        cursor += 6;
        break;
    }
    if (line.spaceAfter > 0) cursor += line.spaceAfter;
  }

  final height = cursor.ceil().clamp(1, 40000);

  final picture = recorder.endRecording();
  final rendered = await picture.toImage(widthDots * ss, height * ss);
  final bytes = await rendered.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  final rgba = bytes!.buffer.asUint8List();
  final srcW = widthDots * ss;

  // Ink coverage of a straight-RGBA pixel over white paper:
  //   displayed = lum * a/255 + 255 * (1 - a/255)
  //   ink       = 1 - displayed/255 = a * (255 - lum) / 255^2
  // Black text anti-aliases through its alpha; logo greys darken through
  // luminance — one formula covers both. A dot prints black when the average
  // coverage of its ss x ss box is >= 50%.
  final halfInk = 255 * 255 * ss * ss ~/ 2;

  final rowBytes = (widthDots + 7) ~/ 8;
  final out = Uint8List(rowBytes * height);
  var o = 0;
  for (var row = 0; row < height; row++) {
    var bit = 0x80;
    for (var x = 0; x < widthDots; x++) {
      var inkSum = 0;
      for (var dy = 0; dy < ss; dy++) {
        final rowStart = ((row * ss + dy) * srcW + x * ss) * 4;
        for (var dx = 0; dx < ss; dx++) {
          final i = rowStart + dx * 4;
          final a = rgba[i + 3];
          if (a == 0) continue;
          final r = rgba[i];
          final g = rgba[i + 1];
          final b = rgba[i + 2];
          final lum = (r == 0 && g == 0 && b == 0)
              ? 0
              : ((77 * r + 150 * g + 29 * b) >> 8);
          inkSum += a * (255 - lum);
        }
      }
      if (inkSum >= halfInk) out[o] |= bit;
      bit = bit >> 1;
      if (bit == 0) {
        bit = 0x80;
        o++;
      }
    }
    if (bit != 0x80) o++; // begin new row byte run
  }

  rendered.dispose();

  var firstInkRow = -1;
  var lastInkRow = -1;
  for (var row = 0; row < height; row++) {
    final rowOffset = row * rowBytes;
    var hasInk = false;
    for (var b = 0; b < rowBytes; b++) {
      if (out[rowOffset + b] != 0) {
        hasInk = true;
        break;
      }
    }
    if (hasInk) {
      if (firstInkRow < 0) firstInkRow = row;
      lastInkRow = row;
    }
  }
  if (firstInkRow >= 0 && lastInkRow >= firstInkRow) {
    final trimmedHeight = lastInkRow - firstInkRow + 1;
    final trimmed = Uint8List.sublistView(
      out,
      firstInkRow * rowBytes,
      (lastInkRow + 1) * rowBytes,
    );
    return RasterBitmap(Uint8List.fromList(trimmed), widthDots, trimmedHeight);
  }
  return RasterBitmap(Uint8List(rowBytes), widthDots, 1);
}

/// Luminance helper exposed for tests.
int luminance(int r, int g, int b) =>
    (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
