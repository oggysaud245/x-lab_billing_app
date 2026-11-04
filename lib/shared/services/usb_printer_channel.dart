/// Thin wrapper over the Android USB host platform channel.
/// Kotlin side: MainActivity.kt `usb_printer` channel handler.
library;


import 'package:flutter/services.dart';

import '../models/printer.dart';

class UsbPrinterChannel {
  static const _channel = MethodChannel('usb_printer');

  /// Lists USB devices that look like printers (class 7 or bulk-out).
  static Future<List<UsbPrinterDevice>> listDevices() async {
    try {
      final raw = await _channel.invokeListMethod<Map>('listDevices');
      return (raw ?? [])
          .map((m) => UsbPrinterDevice.fromMap(m.cast<Object?, Object?>()))
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  static Future<bool> hasPermission({required int vendorId, required int productId}) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'hasPermission',
        {'vendorId': vendorId, 'productId': productId},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Requests Android permission for the device; returns true when granted.
  static Future<bool> requestPermission({required int vendorId, required int productId}) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'requestPermission',
        {'vendorId': vendorId, 'productId': productId},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens an interface and claims its bulk-out endpoint.
  static Future<bool> open({required int vendorId, required int productId}) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'open',
        {'vendorId': vendorId, 'productId': productId},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Returns bytes written, or -1 on failure.
  static Future<int> write(Uint8List bytes) async {
    try {
      final n = await _channel.invokeMethod<int>('write', {'bytes': bytes});
      return n ?? -1;
    } on PlatformException {
      return -1;
    } on MissingPluginException {
      return -1;
    }
  }

  /// Releases interface & closes connection.
  static Future<void> close() async {
    try {
      await _channel.invokeMethod('close');
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }
}
