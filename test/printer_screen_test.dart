// Printer-tab regression: USB device flow renders clean.
//
// Drives the real HomeShell with a mock `usb_printer` channel that reports
// one granted printer (VID 0483 / PID 5740 — the STMicro receipt-board pair
// from the vendor SDK demo), then runs the Test Connection / Test Print
// actions. Any framework layout exception thrown during these frames fails
// with the full widget chain ("RenderBox was not laid out" would surface here).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xlab_billing/core/db/app_database.dart';
import 'package:xlab_billing/features/home_shell.dart';
import 'package:xlab_billing/localization/app_localizations.dart';
import 'package:xlab_billing/shared/controllers/app_state.dart';
import 'package:xlab_billing/shared/controllers/billing_state.dart';
import 'package:xlab_billing/shared/controllers/printer_state.dart';
import 'package:xlab_billing/shared/models/printer.dart';
import 'package:xlab_billing/shared/repositories/invoice_repository.dart';
import 'package:xlab_billing/shared/repositories/printer_repository.dart';
import 'package:xlab_billing/shared/services/printer_discovery.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    await db.close();
  });

  Future<PrinterController> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('usb_printer'),
      (call) async {
        switch (call.method) {
          case 'listDevices':
            return [
              {
                'vendorId': 0x0483,
                'productId': 0x5740,
                'deviceName': '/dev/bus/usb/001/002',
                'hasPermission': true,
              },
            ];
          case 'hasPermission':
          case 'requestPermission':
          case 'open':
            return true;
          case 'write':
            return (call.arguments?['bytes'] as List?)?.length ?? 0;
          case 'close':
            return true;
        }
        return null;
      },
    );

    final app = AppState();
    final billing = BillingController(app: app);
    final printer = PrinterController(
      printers: PrinterRepository(open: () => throw UnimplementedError()),
      invoiceRepo: InvoiceRepository(open: () => throw UnimplementedError()),
      discovery: PrinterDiscoveryService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<BillingController>.value(value: billing),
          ChangeNotifierProvider<PrinterController>.value(value: printer),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Printer tab (index 3).
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.print_outlined),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return printer;
  }

  testWidgets('printer tab: USB device flow runs without layout exceptions',
      (tester) async {
    final printer = await pumpApp(tester);

    // Device appears via the same channel the real refresh button calls.
    await printer.refreshUsbDevices();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The granted USB printer tile renders: device path row + select action.
    expect(find.text('/dev/bus/usb/001/002', skipOffstage: false),
        findsOneWidget);

    // Test Connection → status flips connecting/connected → snackbar path.
    await tester.ensureVisible(find.text('Test Connection'));
    await tester.tap(find.text('Test Connection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // Test Print → builds + sends the self-test raster receipt.
    await tester.ensureVisible(find.text('Test Print'));
    await tester.tap(find.text('Test Print'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  test('controller: saving the USB device selects it as default', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    final printer = PrinterController(
      printers: PrinterRepository(open: () async => db),
      invoiceRepo: InvoiceRepository(open: () async => db),
      discovery: PrinterDiscoveryService(),
    );

    const usbDevice = PrinterConfig(
      id: 0,
      displayName: '/dev/bus/usb/001/002',
      connectionType: ConnectionType.usb,
      host: '',
      port: 0,
      usbVendorId: 0x0483,
      usbProductId: 0x5740,
      usbDeviceName: '/dev/bus/usb/001/002',
      paperWidthMm: 58,
      renderingMode: RenderingMode.auto,
      enableCut: true,
      enableBeep: false,
      enableDrawer: false,
      isSelected: true,
      updatedAt: 0,
    );

    await printer.save(usbDevice);

    expect(printer.selected?.usbVendorId, 0x0483);
    expect(printer.selected?.connectionType, ConnectionType.usb);
    expect(printer.selected?.usbDeviceName, '/dev/bus/usb/001/002');

    // Re-tapping Select on the same device must not stack duplicates: the
    // second save reuses the stored configuration as the selected default.
    await printer.save(usbDevice);
    expect(await printersRowCount(db), 1);
    expect(printer.selected?.id, printer.configs.single.id);

    // A different printer is still a distinct configuration.
    await printer.save(const PrinterConfig(
      id: 0,
      displayName: '/dev/bus/usb/001/003',
      connectionType: ConnectionType.usb,
      host: '',
      port: 0,
      usbVendorId: 0x0483,
      usbProductId: 0x5740,
      usbDeviceName: '/dev/bus/usb/001/003',
      paperWidthMm: 58,
      renderingMode: RenderingMode.auto,
      enableCut: true,
      enableBeep: false,
      enableDrawer: false,
      isSelected: true,
      updatedAt: 0,
    ));
    expect(await printersRowCount(db), 2);

    // Rename overwriting on explicit edit still works; identity reuse with
    // a different derived name keeps a user-chosen display name.
    final renamable = printer.configs
        .singleWhere((c) => c.usbDeviceName == '/dev/bus/usb/001/002');
    await printer.save(usbDevice.copyWith(displayName: 'Counter'),
        existingId: renamable.id);
    final row = printer.configs
        .singleWhere((c) => c.usbDeviceName == '/dev/bus/usb/001/002');
    expect(row.displayName, 'Counter');
    expect(await printersRowCount(db), 2);

    // Manual add (no device path known) of the same model reuses the stored
    // configuration too.
    await printer.save(usbDevice.copyWith(
        displayName: 'Manual', usbDeviceName: ''));
    expect(await printersRowCount(db), 2);

    await db.close();
  });

  test('controller: background check updates USB connection status', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);

    var mockDevices = <Map<String, dynamic>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('usb_printer'),
      (call) async {
        if (call.method == 'listDevices') return mockDevices;
        return null;
      },
    );

    final printer = PrinterController(
      printers: PrinterRepository(open: () async => db),
      invoiceRepo: InvoiceRepository(open: () async => db),
      discovery: PrinterDiscoveryService(),
      autoCheck: false,
    );

    const usbConfig = PrinterConfig(
      id: 0,
      displayName: 'USB Counter',
      connectionType: ConnectionType.usb,
      host: '',
      port: 0,
      usbVendorId: 0x0483,
      usbProductId: 0x5740,
      usbDeviceName: '/dev/bus/usb/001/002',
      paperWidthMm: 58,
      renderingMode: RenderingMode.auto,
      enableCut: true,
      enableBeep: false,
      enableDrawer: false,
      isSelected: true,
      updatedAt: 0,
    );

    await printer.save(usbConfig);
    // Initially not in mockDevices -> disconnected
    expect(printer.status, PrinterStatus.disconnected);

    // Device plugged in but permission not yet granted
    mockDevices = [
      {
        'vendorId': 0x0483,
        'productId': 0x5740,
        'deviceName': '/dev/bus/usb/001/002',
        'hasPermission': false,
      },
    ];
    await printer.checkConnection();
    expect(printer.status, PrinterStatus.usbPermissionRequired);

    // Permission granted
    mockDevices = [
      {
        'vendorId': 0x0483,
        'productId': 0x5740,
        'deviceName': '/dev/bus/usb/001/002',
        'hasPermission': true,
      },
    ];
    await printer.checkConnection();
    expect(printer.status, PrinterStatus.connected);

    // Unplugged
    mockDevices = [];
    await printer.checkConnection();
    expect(printer.status, PrinterStatus.disconnected);

    printer.dispose();
    await db.close();
  });
}

Future<int> printersRowCount(dynamic db) async {
  final rows = await db.query('printer_configurations');
  return rows.length;
}
