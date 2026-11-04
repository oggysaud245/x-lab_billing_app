/// WYSIWYG receipt preview (raster bitmap, exactly what the printer gets in
/// image mode) with the print action and a language override for the
/// preview only.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/controllers/printer_state.dart';
import '../../shared/models/invoice.dart';
import '../../shared/services/print_service.dart';
import '../../shared/services/receipt_bitmap.dart';
import '../../shared/widgets/widgets_extra.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final Invoice invoice;

  const ReceiptPreviewScreen({super.key, required this.invoice});

  static Route<ReceiptPreviewScreen> route(Invoice invoice) =>
      MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(invoice: invoice));

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  bool _busy = false;
  String? _langOverride;
  Future<ui.Image?>? _previewFuture;
  int? _lastPaperWidthMm;

  void _updatePreview(int? paperWidthMm) {
    _lastPaperWidthMm = paperWidthMm;
    _previewFuture = _loadPreview(paperWidthMm, _langOverride);
  }

  @override
  void didUpdateWidget(ReceiptPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invoice != oldWidget.invoice) {
      _updatePreview(_lastPaperWidthMm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final paperWidth = context.select<PrinterController, int?>(
      (p) => p.selected?.paperWidthMm,
    );
    final hasPrinter = context.select<PrinterController, bool>(
      (p) => p.selected != null,
    );

    if (_previewFuture == null || _lastPaperWidthMm != paperWidth) {
      _updatePreview(paperWidth);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.previewInvoice)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: EnumSegment<String>(
                    label: l.selectedFormatHint,
                    values: const ['', 'en', 'ne'],
                    labelOf: (v) {
                      switch (v) {
                        case 'en':
                          return l.invoiceLanguageEnglish;
                        case 'ne':
                          return l.invoiceLanguageNepali;
                        default:
                          // Distinct label — the bare language name would
                          // duplicate the forced 'en'/'ne' chips below.
                          return l.previewLanguageDefault(_invoiceLangLabel(
                              l, widget.invoice.invoiceLanguage));
                      }
                    },
                    selected: _langOverride ?? '',
                    // Empty chip means "follow the invoice" — encode it as
                    // null, never as '', so no invalid locale code reaches
                    // the layout engine after switching languages manually.
                    onChanged: (v) {
                      setState(() {
                        _langOverride = v.isEmpty ? null : v;
                        _updatePreview(_lastPaperWidthMm);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: RepaintBoundary(
                child: FutureBuilder<ui.Image?>(
                  future: _previewFuture,
                  builder: (context, snap) {
                    if (snap.hasData && snap.data != null) {
                      final img = snap.data!;
                      return SingleChildScrollView(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RawImage(image: img),
                          ],
                        ),
                      );
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyView(
                        text: l.previewLoadFailed,
                        icon: Icons.image_not_supported_outlined,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: !hasPrinter
                  ? () => showAppSnackBar(context, l.selectPrinterFirst)
                  : (_busy
                      ? null
                      : () => _print(
                          context, context.read<PrinterController>(), l)),
              icon: const Icon(Icons.print),
              label: Text(l.printInvoice),
            ),
          ),
        ],
      ),
    );
  }

  String _invoiceLangLabel(AppLocalizations l, InvoiceLanguage lang) =>
      switch (lang) {
        InvoiceLanguage.en => l.invoiceLanguageEnglish,
        InvoiceLanguage.ne => l.invoiceLanguageNepali,
      };

  Future<ui.Image?> _loadPreview(
      int? paperWidthMm, String? langOverride) async {
    const orch = PrintOrchestrator();
    final bitmap = await orch.renderPreview(
      widget.invoice,
      languageOverride: langOverride,
      paperWidthMm: paperWidthMm,
    );
    if (bitmap == null) return null;
    return rasterToUiImage(bitmap);
  }

  Future<void> _print(
    BuildContext context,
    PrinterController printerCtrl,
    AppLocalizations l,
  ) async {
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    showAppSnackBar(context, l.printSendingMsg);
    final sent = await printerCtrl.printInvoice(
      widget.invoice,
      languageOverride: _langOverride,
    );
    app.notifyDataChanged();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      sent
          ? l.printSentMsg
          : '${l.printAttemptFailed}'
              '${printerCtrl.statusDetail == null || printerCtrl.statusDetail!.isEmpty ? '' : ' · ${printerCtrl.statusDetail}'}',
    );
    if (sent) {
      app.requestBillingTab();
      nav.popUntil((route) => route.isFirst);
    }
  }
}

/// Converts the packed 1-bit printer data into a displayable image without
/// altering the page geometry (white paper, black dots).
Future<ui.Image> rasterToUiImage(RasterBitmap bitmap) async {
  final w = bitmap.widthDots;
  final h = bitmap.heightDots;
  final packed = bitmap.packedRows;
  final bytesPerRow = (w + 7) ~/ 8;
  final rgba = Uint8List(w * h * 4);
  var o = 0;
  for (var y = 0; y < h; y++) {
    final base = y * bytesPerRow;
    for (var x = 0; x < w; x++) {
      final b = packed[base + (x >> 3)];
      final v = (b & (0x80 >> (x & 7))) == 0 ? 255 : 0;
      rgba[o++] = v;
      rgba[o++] = v;
      rgba[o++] = v;
      rgba[o++] = 255;
    }
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec =
      await descriptor.instantiateCodec(targetWidth: w, targetHeight: h);
  final frame = await codec.getNextFrame();
  codec.dispose();
  descriptor.dispose();
  return frame.image;
}
