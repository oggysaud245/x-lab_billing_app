// LAN discovery rendering regression: discovered-printer tiles must lay out
// without exceptions at any viewport width / font scale.
//
// PrinterPage is pumped standalone (not inside the HomeShell) so background
// loads of hidden IndexedStack tabs cannot spawn sqflite transaction
// watchdog timers that race the test's FakeAsync zone.
//
// Real-device bug: the discovered result ListTile had a wide
// FilledButton.tonalIcon in `trailing`. On narrow tiles (~350px phones,
// ~599px on the tablet) ListTile's layout assertion
// "Trailing widget consumes the entire tile width" fired DURING performLayout,
// the tile subtree never got a size, and every later frame re-failed —
// rendering the whole LAN section card BLANK with no error box.

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
import 'package:xlab_billing/shared/models/printer.dart';
import 'package:xlab_billing/shared/repositories/invoice_repository.dart';
import 'package:xlab_billing/shared/repositories/printer_repository.dart';
import 'package:xlab_billing/shared/services/printer_discovery.dart';

/// Discovery service stand-in: returns one completed scan.
class _FakeDiscovery extends PrinterDiscoveryService {
  _FakeDiscovery(this.found);

  final List<DiscoveredPrinter> found;

  @override
  Future<String?> localAddress() async => '192.168.1.23';

  @override
  Future<List<DiscoveredPrinter>> scanSubnet({
    required String baseIp,
    required int port,
    int timeoutMs = 250,
    int concurrency = 24,
    void Function(int done, int total)? onProgress,
    bool Function()? shouldContinue,
  }) async {
    onProgress?.call(254, 254);
    return found;
  }
}

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

  Future<void> pumpAndDiscover(
    WidgetTester tester, {
    required List<DiscoveredPrinter> found,
    // Default mimics the real tablet: Xiaomi Pad 6, 1600x2560 @ MIUI
    // density 360 → ~671x1130 logical. ListTile's device assert fired at
    // this same tile width, so this is the primary reproduction target.
    Size logicalSize = const Size(671, 1130),
    double dpr = 2.0,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = logicalSize * dpr;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('usb_printer'),
      (call) async {
        switch (call.method) {
          case 'listDevices':
            return <Object>[];
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
      discovery: _FakeDiscovery(found),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<BillingController>.value(value: billing),
          ChangeNotifierProvider<PrinterController>.value(value: printer),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            locale: const Locale('en'),
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

    // .icon variants create private ButtonStyleButton subclasses, so type
    // matching must be byWidgetPredicate (see AGENTS.md finder traps). On
    // narrow viewports the LAN section sits beyond the viewport, which the
    // finder treats as offstage — hence skipOffstage:false + scroll first.
    final scan = find.ancestor(
      of: find.text('Find Printers', skipOffstage: false),
      matching:
          find.byWidgetPredicate((w) => w is FilledButton, skipOffstage: false),
    );
    // On narrow viewports the LAN section starts below the fold: drag the
    // list up so the scan subtree mounts before we tap it.
    expect(scan, findsOneWidget);
    final listWater = find.byType(ListView, skipOffstage: false).first;
    await tester.drag(listWater, const Offset(0, -900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('tiles without a resolved name keep ip + port display',
      (tester) async {
    // The real service leaves name empty when the mDNS sweep resolves
    // nothing for a host (the common case for bare receipt boards), and the
    // tile falls back to the ip + port display.
    await pumpAndDiscover(tester, found: const [
      DiscoveredPrinter(host: '10.0.0.5', port: 9100, name: ''),
      DiscoveredPrinter(host: '10.0.0.6', port: 9100, name: '10.0.0.6'),
    ]);
    expect(tester.takeException(), isNull);
    expect(find.text('10.0.0.5'), findsOneWidget);
    expect(find.text('10.0.0.6'), findsOneWidget);
    expect(find.text('port 9100'), findsNWidgets(2));
  });

  testWidgets('completed LAN scan renders results without layout exceptions',
      (tester) async {
    await pumpAndDiscover(tester, found: const [
      DiscoveredPrinter(host: '192.168.1.100', port: 9100, name: 'xlab-1'),
      DiscoveredPrinter(host: '192.168.1.101', port: 9100, name: 'xlab-2'),
    ]);
    expect(tester.takeException(), isNull);
    // The result tiles must use the deterministic LayoutBuilder/Row pattern
    // (ValueKey 'lan-dev-…'), NOT a ListTile with a trailing button: on real
    // Impeller/Vulkan hardware the trailing button once laid out at exactly
    // the full tile width, failing ListTile's layout assert every frame and
    // blanking the whole LAN card. Reintroducing the ListTile pattern makes
    // both these key finds fail.
    expect(find.byKey(const ValueKey('lan-dev-192.168.1.100:9100')), findsOneWidget);
    expect(find.byKey(const ValueKey('lan-dev-192.168.1.101:9100')), findsOneWidget);
    expect(find.text('LAN / Wi-Fi'), findsWidgets);
    // Resolved name: headline, with ip + port as the detail line.
    expect(find.text('xlab-1'), findsOneWidget);
    expect(find.text('xlab-2'), findsOneWidget);
    expect(find.text('192.168.1.100 · port 9100'), findsOneWidget);
    expect(find.text('192.168.1.101 · port 9100'), findsOneWidget);
    expect(
        find.text(
            'Printers on port 9100 are found by scanning the local network.'),
        findsOneWidget);
  });

  testWidgets(
      'completed LAN scan renders results without layout exceptions on a narrow phone',
      (tester) async {
    await pumpAndDiscover(tester, found: const [
      DiscoveredPrinter(host: '192.168.1.100', port: 9100, name: 'xlab-1'),
      DiscoveredPrinter(host: '192.168.1.101', port: 9100, name: 'xlab-2'),
    ], logicalSize: const Size(360, 640), dpr: 3.0,
        textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(
        find.text('192.168.1.100 · port 9100', skipOffstage: false),
        findsOneWidget);
    expect(
        find.text('192.168.1.101 · port 9100', skipOffstage: false),
        findsOneWidget);
    // Geometry: the full result line must sit inside its SectionCard —
    // mirrors the device defect class ("results overflowed the card").
    for (final line in const ['192.168.1.100 · port 9100', '192.168.1.101 · port 9100']) {
      final textFinder = find.text(line, skipOffstage: false);
      final textRect = tester.getRect(textFinder);
      final cardRect = tester.getRect(
        find
            .ancestor(
              of: textFinder,
              matching: find.byType(Card, skipOffstage: false),
            )
            .first,
      );
      expect(cardRect.contains(textRect.topLeft), isTrue,
          reason: '$line top-left outside card: $textRect vs $cardRect');
      expect(cardRect.contains(textRect.bottomRight), isTrue,
          reason: '$line bottom-right outside card: $textRect vs $cardRect');
    }
  });

  testWidgets('completed LAN scan with zero results still renders the note',
      (tester) async {
    await pumpAndDiscover(tester, found: const []);
    expect(tester.takeException(), isNull);
    expect(
        find.text(
            'Printers on port 9100 are found by scanning the local network.'),
        findsOneWidget);
  });

  test('Lan address picker skips loopback and prefers private ranges', () {
    expect(PrinterDiscoveryService.pickLanAddress([
      '127.0.0.1',
      '192.168.1.23',
      '10.8.0.2',
    ]), '192.168.1.23');
    expect(
        PrinterDiscoveryService.pickLanAddress(['127.0.0.1', '10.2.3.4']),
        '10.2.3.4');
    // 172.16-31 is private; 172.32+ is not.
    expect(PrinterDiscoveryService.pickLanAddress(['172.16.0.5', '192.168.9.9']),
        '172.16.0.5');
    expect(PrinterDiscoveryService.pickLanAddress(['172.32.0.5']),
        '172.32.0.5');
    // Loopback-only → null (falls back to the public probe in localAddress).
    expect(PrinterDiscoveryService.pickLanAddress(['127.0.0.1', '127.0.0.53']),
        isNull);
    // Non-private, non-loopback IPv4 still usable as a last fallback.
    expect(
        PrinterDiscoveryService.pickLanAddress(['169.254.1.2']), '169.254.1.2');
    // IPv4 selection only; the caller feeds IPv4 strings.
    expect(PrinterDiscoveryService.pickLanAddress(const <String>[]), isNull);
  });

  test('pickLanInterfaceAddress prefers wlan0 over cellular ccmni/rmnet and vgate tunnels', () {
    // Exact interface list observed on an Android phone (CPH2719) with mobile
    // data active alongside Wi-Fi: ccmni1 (10.208.241.71) appears before
    // wlan0 (192.168.1.67) and vgate0 (172.30.228.158) in kernel index order.
    final picked = PrinterDiscoveryService.pickLanInterfaceAddress([
      (interfaceName: 'lo', address: '127.0.0.1'),
      (interfaceName: 'ccmni1', address: '10.208.241.71'),
      (interfaceName: 'wlan0', address: '192.168.1.67'),
      (interfaceName: 'vgate0', address: '172.30.228.158'),
    ]);
    expect(picked, '192.168.1.67');

    // Qualcomm rmnet + WireGuard/VPN tun interfaces are also skipped.
    expect(
      PrinterDiscoveryService.pickLanInterfaceAddress([
        (interfaceName: 'rmnet_data0', address: '10.10.10.5'),
        (interfaceName: 'tun0', address: '172.16.0.2'),
        (interfaceName: 'wlan0', address: '10.0.0.42'),
      ]),
      '10.0.0.42',
    );
  });

  test('discovery headline: mDNS name → saved config name → ip', () {
    const lan = PrinterConfig(
      id: 1,
      displayName: 'yggg',
      connectionType: ConnectionType.lan,
      host: '192.168.1.100',
      port: 9100,
      usbVendorId: null,
      usbProductId: null,
      usbDeviceName: '',
      paperWidthMm: 80,
      renderingMode: RenderingMode.auto,
      enableCut: true,
      enableBeep: false,
      enableDrawer: false,
      isSelected: true,
      updatedAt: 0,
    );
    const host = DiscoveredPrinter(host: '192.168.1.100', port: 9100, name: '');
    // 1. a resolved network name wins;
    expect(
        discoveryHeadline(
            const DiscoveredPrinter(
                host: '192.168.1.100', port: 9100, name: 'SNBC-MINI-1'),
            const [lan]),
        'SNBC-MINI-1');
    // 2. without one, the saved config's user-chosen name is the headline —
    //    the scan so often re-discovers the printer the user already named;
    expect(discoveryHeadline(host, const [lan]), 'yggg');
    // 3. no saved match → the ip (tiles show ip + port only).
    expect(discoveryHeadline(host, const []), '192.168.1.100');
    // 4. a saved name identical to the ip carries no meaning → still the ip.
    const ipNamed = PrinterConfig(
      id: 2,
      displayName: '192.168.1.100',
      connectionType: ConnectionType.lan,
      host: '192.168.1.100',
      port: 9100,
      usbVendorId: null,
      usbProductId: null,
      usbDeviceName: '',
      paperWidthMm: 80,
      renderingMode: RenderingMode.auto,
      enableCut: true,
      enableBeep: false,
      enableDrawer: false,
      isSelected: false,
      updatedAt: 0,
    );
    expect(discoveryHeadline(host, const [ipNamed]), '192.168.1.100');
  });
}
