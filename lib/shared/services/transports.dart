/// Printer transports: shared interface plus LAN (socket), USB (platform
/// channel) and mock implementations.
///
/// A transport mirrors one print job: open → send → close. This keeps state
/// management simple and survives flaky printers.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'usb_printer_channel.dart';

abstract class ReceiptTransport {
  Future<void> open();
  Future<void> send(Uint8List bytes);
  Future<void> close();
}

/// LAN/Wi-Fi transport: raw TCP socket to host:port (default 9100).
class LanReceiptTransport implements ReceiptTransport {
  final String host;
  final int port;
  final Duration timeout;
  final Duration chunkDelay;
  Socket? _socket;
  StreamSubscription<Uint8List>? _sub;
  Completer<void>? _peerClosed;

  LanReceiptTransport({
    required this.host,
    this.port = 9100,
    this.timeout = const Duration(seconds: 4),
    this.chunkDelay = Duration.zero,
  });

  @override
  Future<void> open() async {
    final s = await Socket.connect(host, port, timeout: timeout);
    s.setOption(SocketOption.tcpNoDelay, true);
    final peerClosed = Completer<void>();
    _peerClosed = peerClosed;
    // Drain any status bytes sent by the printer so the OS receive buffer is
    // empty on close (closing with unread RX bytes forces a TCP RST instead of
    // a clean FIN), and detect when the printer finishes its FIN handshake.
    _sub = s.listen(
      (_) {},
      onError: (_) {
        if (!peerClosed.isCompleted) peerClosed.complete();
      },
      onDone: () {
        if (!peerClosed.isCompleted) peerClosed.complete();
      },
      cancelOnError: true,
    );
    _socket = s;
  }

  @override
  Future<void> send(Uint8List bytes) async {
    final s = _socket;
    if (s == null) throw StateError('LanReceiptTransport not open');
    const chunk = 16384;
    for (var i = 0; i < bytes.length; i += chunk) {
      final end = i + chunk > bytes.length ? bytes.length : i + chunk;
      s.add(Uint8List.sublistView(bytes, i, end));
      if (end < bytes.length && chunkDelay > Duration.zero) {
        await s.flush();
        await Future<void>.delayed(chunkDelay);
      }
    }
    await s.flush();
  }

  @override
  Future<void> close() async {
    final s = _socket;
    final sub = _sub;
    final peerClosed = _peerClosed;
    _socket = null;
    _sub = null;
    _peerClosed = null;
    if (s == null) return;
    try {
      await s.flush().timeout(const Duration(seconds: 2));
      await s.close().timeout(const Duration(seconds: 2));
      if (peerClosed != null) {
        await peerClosed.future.timeout(
          const Duration(milliseconds: 50),
          onTimeout: () {},
        );
      }
    } catch (_) {
      // ignore
    } finally {
      try {
        await sub?.cancel();
      } catch (_) {
        // ignore
      }
      try {
        s.destroy();
      } catch (_) {
        // ignore
      }
    }
  }
}

/// USB transport delegating to the platform channel.
class UsbReceiptTransport implements ReceiptTransport {
  final int vendorId;
  final int productId;

  const UsbReceiptTransport({required this.vendorId, required this.productId});

  @override
  Future<void> open() async {
    final granted = await UsbPrinterChannel.hasPermission(vendorId: vendorId, productId: productId);
    if (!granted) {
      final ok = await UsbPrinterChannel.requestPermission(vendorId: vendorId, productId: productId);
      if (!ok) throw const TransportError('USB_PERMISSION_DENIED');
    }
    final opened = await UsbPrinterChannel.open(vendorId: vendorId, productId: productId);
    if (!opened) throw const TransportError('USB_OPEN_FAILED');
  }

  @override
  Future<void> send(Uint8List bytes) async {
    const chunk = 16384;
    for (var i = 0; i < bytes.length; i += chunk) {
      final end = i + chunk > bytes.length ? bytes.length : i + chunk;
      final n = await UsbPrinterChannel.write(bytes.sublist(i, end));
      if (n < 0) throw const TransportError('USB_WRITE_FAILED');
    }
  }

  @override
  Future<void> close() => UsbPrinterChannel.close();
}

/// Mock transport for automated tests/demo mode — never used for real
/// printing. Records sent bytes.
class MockReceiptTransport implements ReceiptTransport {
  final List<Uint8List> sentChunks = [];
  final bool succeed;

  MockReceiptTransport({this.succeed = true});

  bool opened = false;

  @override
  Future<void> open() async {
    if (!succeed) throw const TransportError('MOCK_CONNECT_FAILED');
    opened = true;
  }

  @override
  Future<void> send(Uint8List bytes) async {
    if (!succeed) throw const TransportError('MOCK_WRITE_FAILED');
    sentChunks.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> close() async {
    opened = false;
  }

  Uint8List get allBytes {
    final b = BytesBuilder();
    for (final c in sentChunks) {
      b.add(c);
    }
    return b.toBytes();
  }
}

final class TransportError implements Exception {
  final String code;
  const TransportError(this.code);

  @override
  String toString() => code;
}
