// Regression: the USB card must contain its device rows on a phone-sized
// viewport even with large fonts and long device names — guards against the
// "results overlapping the parent card" rendering defect reported on device
// (any child painting outside its SectionCard bounds fails this test).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xlab_billing/core/db/app_database.dart';
import 'package:xlab_billing/features/printer/printer_screen.dart';
import 'package:xlab_billing/localization/app_localizations.dart';
import 'package:xlab_billing/shared/controllers/app_state.dart';
import 'package:xlab_billing/shared/controllers/billing_state.dart';
import 'package:xlab_billing/shared/controllers/printer_state.dart';
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

  testWidgets('usb card contains its rows on a phone-sized viewport',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0; // logical 360x640
    addTearDown(tester.view.reset);

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
                'deviceName': '/dev/bus/usb/001/002_long_device_path_name',
                'hasPermission': false,
              },
              {
                'vendorId': 0x0483,
                'productId': 0x5740,
                'deviceName': '/dev/bus/usb/001/003',
                'hasPermission': true,
              },
            ];
          case 'requestPermission':
            return true;
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
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            locale: const Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const PrinterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await printer.refreshUsbDevices();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(printer.usbDevices.length, 2);
    expect(tester.takeException(), isNull);

    // Device rows exist (below the fold → skipOffstage:false).
    final pathTexts = find.textContaining('/dev/bus/usb', skipOffstage: false);
    debugPrint('USB_PATHS=${pathTexts.evaluate().length}');    expect(pathTexts, findsNWidgets(2));

    for (final el in pathTexts.evaluate()) {
      final textFinder = find.byWidget(el.widget, skipOffstage: false);
      final textRect = tester.getRect(textFinder);
      final cardRect = tester.getRect(find
          .ancestor(
            of: textFinder,
            matching: find.byType(Card, skipOffstage: false),
          )
          .first);
      debugPrint('USB_RECTS text=$textRect card=$cardRect inside='
          '${cardRect.contains(textRect.topLeft) && cardRect.contains(textRect.bottomRight)}');
      expect(cardRect.contains(textRect.topLeft), isTrue,
          reason: 'text top-left outside card: $textRect vs $cardRect');
      expect(cardRect.contains(textRect.bottomRight), isTrue,
          reason: 'text bottom-right outside card: $textRect vs $cardRect');
    }

    // VID:PID rows likewise.
    final idTexts = find.textContaining('1155:22336', skipOffstage: false);
    debugPrint('USB_IDTEXTS=${idTexts.evaluate().length}');
    expect(idTexts, findsNWidgets(2));
    for (final el in idTexts.evaluate()) {
      final textFinder = find.byWidget(el.widget, skipOffstage: false);
      final textRect = tester.getRect(textFinder);
      final cardRect = tester.getRect(find
          .ancestor(
            of: textFinder,
            matching: find.byType(Card, skipOffstage: false),
          )
          .first);
      debugPrint('USB_RECTS id=$textRect card=$cardRect inside='
          '${cardRect.contains(textRect.topLeft) && cardRect.contains(textRect.bottomRight)}');
      expect(cardRect.contains(textRect.topLeft), isTrue,
          reason: 'text top-left outside card: $textRect vs $cardRect');
      expect(cardRect.contains(textRect.bottomRight), isTrue,
          reason: 'text bottom-right outside card: $textRect vs $cardRect');
    }

    expect(tester.takeException(), isNull);
  });
}
