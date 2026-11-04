/// Printer session: saved configurations, the selected printer, discovery,
/// USB permission flow, connection status and sending receipts.
///
/// Status machine: notSelected → disconnected → searching / connecting →
/// connected → busy / sending → error → usbPermissionRequired. [statusDetail]
/// carries a raw detail string (e.g. the transport error code) that screens
/// localize.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import '../models/invoice.dart';
import '../models/print_job.dart';
import '../models/printer.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/printer_repository.dart';
import '../services/print_service.dart';
import '../services/printer_discovery.dart';
import '../services/transports.dart';
import '../services/usb_printer_channel.dart';

class PrinterController extends ChangeNotifier {
  final PrinterRepository printers;
  final InvoiceRepository invoiceRepo;
  final PrinterDiscoveryService discovery;
  final PrintOrchestrator orchestrator;
  final Duration pollInterval;
  final bool autoCheck;

  PrinterController({
    required this.printers,
    required this.invoiceRepo,
    required this.discovery,
    this.orchestrator = const PrintOrchestrator(),
    this.pollInterval = const Duration(seconds: 2),
    this.autoCheck = true,
  });

  List<PrinterConfig> _configs = [];
  PrinterConfig? _selected;

  PrinterStatus _status = PrinterStatus.notSelected;
  String? _statusDetail;
  Timer? _connectedTimer;
  Timer? _pollTimer;
  bool _checking = false;

  // Discovery state.
  bool _scanning = false;
  int _scanDone = 0;
  int _scanTotal = 0;
  List<DiscoveredPrinter> _discovered = [];

  // USB state.
  List<UsbPrinterDevice> _usbDevices = [];

  List<PrinterConfig> get configs => List.unmodifiable(_configs);
  PrinterConfig? get selected => _selected;
  PrinterStatus get status => _status;
  String? get statusDetail => _statusDetail;
  bool get isChecking => _checking;
  bool get scanning => _scanning;
  int get scanDone => _scanDone;
  int get scanTotal => _scanTotal;
  List<DiscoveredPrinter> get discovered => List.unmodifiable(_discovered);
  List<UsbPrinterDevice> get usbDevices => List.unmodifiable(_usbDevices);

  void _setStatus(PrinterStatus s, {String? detail}) {
    if (_status == s && _statusDetail == detail) return;
    _status = s;
    _statusDetail = detail;
    notifyListeners();
  }

  void startPolling() {
    stopPolling();
    _pollTimer = Timer.periodic(pollInterval, (_) => checkConnection());
    unawaited(checkConnection());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Loads saved configurations and the selected one.
  Future<void> load() async {
    _configs = await printers.list();
    _selected = await printers.selected();
    _refreshSelectionStatus();
    if (autoCheck) {
      startPolling();
    } else {
      await checkConnection();
    }
    notifyListeners();
  }

  Future<List<PrintJob>> printJobsFor(int invoiceId) async =>
      invoiceRepo.printJobsFor(invoiceId);

  Future<int> printCount(int invoiceId) => invoiceRepo.printCount(invoiceId);

  // --- Configuration ---------------------------------------------------------
  Future<void> select(int configId) async {
    await printers.select(configId);
    _configs = await printers.list();
    _selected = await printers.selected();
    _refreshSelectionStatus();
    notifyListeners();
    await checkConnection();
  }

  /// Inserts (id <= 0) or updates a configuration and selects it.
  Future<PrinterConfig> save(PrinterConfig config, {int? existingId}) async {
    await printers.saveAndSelect(existingId: existingId, config: config);
    _configs = await printers.list();
    _selected = await printers.selected();
    _refreshSelectionStatus();
    notifyListeners();
    await checkConnection();
    return (existingId == null || existingId <= 0)
        ? (_selected ?? config)
        : config.copyWith(isSelected: true);
  }

  Future<void> forget(PrinterConfig config) async {
    await printers.forget(config.id);
    _configs = await printers.list();
    _selected = await printers.selected();
    _refreshSelectionStatus();
    notifyListeners();
    await checkConnection();
  }

  void _refreshSelectionStatus() {
    _setStatus(
      _selected == null
          ? PrinterStatus.notSelected
          : PrinterStatus.disconnected,
    );
  }

  // --- Background Connection Check -------------------------------------------
  /// Probes the selected printer in the background without user interaction.
  /// Flips status to connected, disconnected, or usbPermissionRequired.
  Future<void> checkConnection() async {
    if (_status == PrinterStatus.sending ||
        _status == PrinterStatus.busy ||
        _scanning ||
        _checking) {
      return;
    }
    _checking = true;
    try {
      final config = _selected;
      if (config == null) {
        if (_status != PrinterStatus.notSelected) {
          _setStatus(PrinterStatus.notSelected);
        }
        await _pollUsbDevicesIfChanged();
        return;
      }
      if (config.connectionType == ConnectionType.lan) {
        await _checkLanConnection(config);
      } else if (config.connectionType == ConnectionType.usb) {
        await _checkUsbConnection(config);
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkLanConnection(PrinterConfig config) async {
    if (config.host.isEmpty) {
      _setStatus(PrinterStatus.disconnected);
      return;
    }
    final port = config.port <= 0 ? 9100 : config.port;
    try {
      final socket = await Socket.connect(
        config.host,
        port,
        timeout: const Duration(milliseconds: 1500),
      );
      try {
        socket.destroy();
      } catch (_) {}
      _setStatusConnected();
    } on SocketException catch (e) {
      _setStatus(
        PrinterStatus.disconnected,
        detail: e.osError?.message ?? e.message,
      );
    } on TimeoutException {
      _setStatus(PrinterStatus.disconnected, detail: 'timeout');
    } catch (e) {
      _setStatus(PrinterStatus.disconnected, detail: '$e');
    }
  }

  Future<void> _checkUsbConnection(PrinterConfig config) async {
    try {
      final devices = await UsbPrinterChannel.listDevices();
      if (!_usbDevicesEqual(_usbDevices, devices)) {
        _usbDevices = devices;
        notifyListeners();
      }

      final match = devices.where((d) {
        if (config.usbVendorId != null &&
            config.usbProductId != null &&
            config.usbVendorId! > 0 &&
            config.usbProductId! > 0) {
          return d.vendorId == config.usbVendorId &&
              d.productId == config.usbProductId;
        }
        if (config.usbDeviceName.isNotEmpty) {
          return d.deviceName == config.usbDeviceName;
        }
        return false;
      }).firstOrNull;

      if (match == null) {
        _setStatus(PrinterStatus.disconnected);
      } else if (!match.hasPermission) {
        _setStatus(PrinterStatus.usbPermissionRequired);
      } else {
        _setStatusConnected();
      }
    } on MissingPluginException {
      // Platform channel not available in tests / desktop.
    } catch (_) {
      _setStatus(PrinterStatus.disconnected);
    }
  }

  Future<void> _pollUsbDevicesIfChanged() async {
    try {
      final devices = await UsbPrinterChannel.listDevices();
      if (!_usbDevicesEqual(_usbDevices, devices)) {
        _usbDevices = devices;
        notifyListeners();
      }
    } on MissingPluginException {
      // Platform channel not available in tests/desktop.
    } catch (_) {}
  }

  bool _usbDevicesEqual(List<UsbPrinterDevice> a, List<UsbPrinterDevice> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].vendorId != b[i].vendorId ||
          a[i].productId != b[i].productId ||
          a[i].hasPermission != b[i].hasPermission ||
          a[i].deviceName != b[i].deviceName) {
        return false;
      }
    }
    return true;
  }

  // --- LAN discovery ---------------------------------------------------------
  Future<void> discover() async {
    if (_scanning) return;
    final baseIp = await discovery.localAddress();
    if (baseIp == null) {
      // No local network address available; the screen shows its hint copy
      // rather than crashing — the app stays usable offline.
      _discovered = [];
      notifyListeners();
      return;
    }
    _scanning = true;
    _discovered = [];
    _scanDone = 0;
    _scanTotal = 254;
    _setStatus(PrinterStatus.searching);
    try {
      final found = await discovery.scanSubnet(
        baseIp: baseIp,
        port: 9100,
        timeoutMs: 400,
        onProgress: (done, total) {
          _scanDone = done;
          _scanTotal = total;
          notifyListeners();
        },
        shouldContinue: () => _scanning,
      );
      _discovered = found;
    } finally {
      _scanning = false;
      _refreshSelectionStatus();
      notifyListeners();
    }
  }

  void cancelDiscover() {
    _scanning = false;
    discovery.cancel();
    _refreshSelectionStatus();
    notifyListeners();
  }

  // --- USB -------------------------------------------------------------------
  /// Refreshes the list of USB devices that look like printers.
  Future<void> refreshUsbDevices() async {
    try {
      _usbDevices = await UsbPrinterChannel.listDevices();
    } on MissingPluginException {
      _usbDevices = []; // platform channel not yet implemented (tests/desktop)
    } on Exception {
      _usbDevices = [];
    }
    notifyListeners();
  }

  /// Returns true when the system grants the USB permission.
  ///
  /// The device list is refreshed no matter what the reply says: some OEMs /
  /// immutable-reply install upgrades deliver `granted = false` even after the
  /// user tapped OK, while a fresh `hasPermission` readback is authoritative.
  /// Refreshing on every return keeps the tile in sync without a manual
  /// "USB Devices" re-tap.
  Future<bool> requestUsbPermission(UsbPrinterDevice device) async {
    final ok = await UsbPrinterChannel.requestPermission(
      vendorId: device.vendorId,
      productId: device.productId,
    );
    await refreshUsbDevices();
    await checkConnection();
    return ok;
  }

  // --- Connection ------------------------------------------------------------
  /// Open/close test against the given config (no receipt bytes sent).
  Future<bool> testConnection(PrinterConfig config) async {
    _setStatus(PrinterStatus.connecting);
    try {
      await orchestrator.testConnection(config);
      _setStatusConnected();
      return true;
    } on TransportError catch (e) {
      _statusForError(config, e);
      return false;
    } on SocketException catch (e) {
      _setStatus(
        PrinterStatus.disconnected,
        detail: e.osError?.message ?? e.message,
      );
      return false;
    } on Exception catch (e) {
      _setStatus(PrinterStatus.error, detail: '$e');
      return false;
    }
  }

  /// Sends the built-in bilingual self-test receipt. No invoice job record.
  Future<bool> printTest(
    PrinterConfig config, {
    bool bottomMargin = false,
  }) async {
    _setStatus(PrinterStatus.sending);
    try {
      final bytes = await orchestrator.buildTestReceiptBytes(
        config,
        bottomMargin: bottomMargin,
      );
      await orchestrator.sendBytes(config, bytes);
      _setStatusConnected();
      return true;
    } on TransportError catch (e) {
      _statusForError(config, e);
      return false;
    } on SocketException catch (e) {
      _setStatus(
        PrinterStatus.disconnected,
        detail: e.osError?.message ?? e.message,
      );
      return false;
    } on Exception catch (e) {
      _setStatus(PrinterStatus.error, detail: '$e');
      return false;
    }
  }

  void _setStatusConnected() {
    _connectedTimer?.cancel();
    _setStatus(PrinterStatus.connected);
  }

  void _statusForError(PrinterConfig config, TransportError e) {
    switch (config.connectionType) {
      case ConnectionType.usb:
        _setStatus(
          switch (e.code) {
            'usb_permission' => PrinterStatus.usbPermissionRequired,
            'usb_busy' || 'usb_write' => PrinterStatus.busy,
            _ => PrinterStatus.error,
          },
          detail: e.code,
        );
        break;
      case ConnectionType.lan:
        _setStatus(
          e.code == 'timeout'
              ? PrinterStatus.disconnected
              : PrinterStatus.error,
          detail: e.code,
        );
        break;
    }
  }

  /// Sends the invoice bytes and records a print job for the audit trail.
  /// Returns true when the bytes were handed to the transport — ESC/POS
  /// cannot confirm the physical outcome, so screens show "sent; check
  /// paper" and history keeps per-invoice attempt logs with error details.
  Future<bool> printInvoice(
    Invoice invoice, {
    String? languageOverride,
  }) async {
    final config = _selected;
    if (config == null) {
      _setStatus(PrinterStatus.notSelected);
      return false;
    }
    _setStatus(PrinterStatus.sending);
    Uint8List bytes;
    try {
      bytes = (await orchestrator.buildPrintBytes(
        invoice,
        config,
        languageOverride: languageOverride,
      ))
          .bytes;
    } on Exception catch (e) {
      _setStatus(PrinterStatus.error, detail: '$e');
      return false;
    }
    try {
      await orchestrator.sendBytes(config, bytes);
      _setStatusConnected();
      await _recordJob(invoice.id, config, PrintJobStatus.sent, '');
      return true;
    } on TransportError catch (e) {
      _statusForError(config, e);
      await _recordJob(invoice.id, config, PrintJobStatus.failed, e.code);
      return false;
    } on SocketException catch (e) {
      _setStatus(
        PrinterStatus.disconnected,
        detail: e.osError?.message ?? e.message,
      );
      await _recordJob(
        invoice.id,
        config,
        PrintJobStatus.failed,
        e.osError?.message ?? e.message,
      );
      return false;
    } on Exception catch (e) {
      _setStatus(PrinterStatus.error, detail: '$e');
      await _recordJob(invoice.id, config, PrintJobStatus.failed, '$e');
      return false;
    }
  }

  Future<void> _recordJob(
    int invoiceId,
    PrinterConfig config,
    PrintJobStatus status,
    String errorMessage,
  ) async {
    try {
      await invoiceRepo.recordPrintJob(
        invoiceId: invoiceId,
        status: status,
        connectionType: config.connectionType.code,
        errorMessage: errorMessage,
      );
    } on Exception catch (_) {
      // Job bookkeeping must never mask the primary result.
    }
  }

  @override
  void dispose() {
    stopPolling();
    _connectedTimer?.cancel();
    super.dispose();
  }
}
