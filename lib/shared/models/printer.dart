/// Printer configuration, discovery and status models.
library;

enum ConnectionType { lan, usb }

extension ConnectionTypeX on ConnectionType {
  String get code => this == ConnectionType.lan ? 'lan' : 'usb';
}

/// How bytes are produced for the printer.
/// - text: native ESC/POS character mode (fast, ASCII-only English).
/// - image: raster bitmap (required for reliable Devanagari).
/// - auto: text mode for pure-ASCII receipts, image mode otherwise.
enum RenderingMode { auto, text, image }

extension RenderingModeX on RenderingMode {
  String get code => switch (this) {
        RenderingMode.auto => 'auto',
        RenderingMode.text => 'text',
        RenderingMode.image => 'image',
      };
}

enum PrinterStatus {
  notSelected,
  disconnected,
  searching,
  connecting,
  connected,
  busy,
  error,
  usbPermissionRequired,
  sending,
}

/// A saved printer configuration.
class PrinterConfig {
  final int id;
  final String displayName;
  final ConnectionType connectionType;
  final String host;
  final int port;

  /// USB ids for USB printers.
  final int? usbVendorId;
  final int? usbProductId;
  final String usbDeviceName;

  /// 58 or 80 mm paper.
  final int paperWidthMm;
  final RenderingMode renderingMode;
  final bool enableCut;
  final bool enableBeep;
  final bool enableDrawer;
  final bool isSelected;
  final int updatedAt;

  const PrinterConfig({
    required this.id,
    required this.displayName,
    required this.connectionType,
    required this.host,
    required this.port,
    required this.usbVendorId,
    required this.usbProductId,
    required this.usbDeviceName,
    required this.paperWidthMm,
    required this.renderingMode,
    required this.enableCut,
    required this.enableBeep,
    required this.enableDrawer,
    required this.isSelected,
    required this.updatedAt,
  });

  /// Parses a stored code.
  static ConnectionType connectionTypeOf(String? code) =>
      code == 'usb' ? ConnectionType.usb : ConnectionType.lan;

  static RenderingMode renderingModeOf(String? code) => switch (code) {
        'text' => RenderingMode.text,
        'image' => RenderingMode.image,
        _ => RenderingMode.auto,
      };

  factory PrinterConfig.fromRow(Map<String, Object?> r) => PrinterConfig(
        id: r['id'] as int,
        displayName: r['display_name'] as String? ?? '',
        connectionType: PrinterConfig.connectionTypeOf(r['connection_type'] as String?),
        host: r['host'] as String? ?? '',
        port: r['port'] as int? ?? 9100,
        usbVendorId: r['usb_vendor_id'] as int?,
        usbProductId: r['usb_product_id'] as int?,
        usbDeviceName: r['usb_device_name'] as String? ?? '',
        paperWidthMm: r['paper_width_mm'] as int? ?? 58,
        renderingMode: PrinterConfig.renderingModeOf(r['rendering_mode'] as String?),
        enableCut: (r['enable_cut'] as int? ?? 1) != 0,
        enableBeep: (r['enable_beep'] as int? ?? 0) != 0,
        enableDrawer: (r['enable_drawer'] as int? ?? 0) != 0,
        isSelected: (r['is_selected'] as int? ?? 0) != 0,
        updatedAt: r['updated_at'] as int? ?? 0,
      );

  Map<String, Object?> toRow() => {
        if (id > 0) 'id': id,
        'display_name': displayName,
        'connection_type': connectionType.code,
        'host': host,
        'port': port,
        'usb_vendor_id': usbVendorId,
        'usb_product_id': usbProductId,
        'usb_device_name': usbDeviceName,
        'paper_width_mm': paperWidthMm,
        'rendering_mode': renderingMode.code,
        'enable_cut': enableCut ? 1 : 0,
        'enable_beep': enableBeep ? 1 : 0,
        'enable_drawer': enableDrawer ? 1 : 0,
        'is_selected': isSelected ? 1 : 0,
        'updated_at': updatedAt,
      };

  PrinterConfig copyWith({
    String? displayName,
    ConnectionType? connectionType,
    String? host,
    int? port,
    int? usbVendorId,
    int? usbProductId,
    String? usbDeviceName,
    int? paperWidthMm,
    RenderingMode? renderingMode,
    bool? enableCut,
    bool? enableBeep,
    bool? enableDrawer,
    bool? isSelected,
  }) =>
      PrinterConfig(
        id: id,
        displayName: displayName ?? this.displayName,
        connectionType: connectionType ?? this.connectionType,
        host: host ?? this.host,
        port: port ?? this.port,
        usbVendorId: usbVendorId ?? this.usbVendorId,
        usbProductId: usbProductId ?? this.usbProductId,
        usbDeviceName: usbDeviceName ?? this.usbDeviceName,
        paperWidthMm: paperWidthMm ?? this.paperWidthMm,
        renderingMode: renderingMode ?? this.renderingMode,
        enableCut: enableCut ?? this.enableCut,
        enableBeep: enableBeep ?? this.enableBeep,
        enableDrawer: enableDrawer ?? this.enableDrawer,
        isSelected: isSelected ?? this.isSelected,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

  bool get supportsNepaliInTextMode => false;
}

/// A printer found by discovery (not yet saved).
class DiscoveredPrinter {
  final String host;
  final int port;

  /// Best-effort friendly name from an mDNS/DNS-SD sweep (print-service
  /// instance, or the responder's `.local` hostname). Empty when the LAN
  /// resolves nothing — the UI then shows ip + port only.
  final String name;

  const DiscoveredPrinter({
    required this.host,
    required this.port,
    required this.name,
  });
}

/// A USB device reported by the platform channel.
class UsbPrinterDevice {
  final int vendorId;
  final int productId;
  final String deviceName;
  final bool hasPermission;

  const UsbPrinterDevice({
    required this.vendorId,
    required this.productId,
    required this.deviceName,
    required this.hasPermission,
  });

  factory UsbPrinterDevice.fromMap(Map<Object?, Object?> m) => UsbPrinterDevice(
        vendorId: (m['vendorId'] as num?)?.toInt() ?? 0,
        productId: (m['productId'] as num?)?.toInt() ?? 0,
        deviceName: m['deviceName'] as String? ?? '',
        hasPermission: m['hasPermission'] == true,
      );

  String get labelAutoName => deviceName.isEmpty
      ? 'USB ${vendorId.toRadixString(16)}:${productId.toRadixString(16)}'
      : deviceName;
}

/// Result of a print/send attempt.
enum PrintSendStatus { sent, failed }

class PrintSendResult {
  final PrintSendStatus status;
  final String errorDetail;

  const PrintSendResult.sent() : status = PrintSendStatus.sent, errorDetail = '';
  const PrintSendResult.failed(this.errorDetail)
      : status = PrintSendStatus.failed;
}
