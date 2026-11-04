// Smoke test: the home shell must render once state and providers exist.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xlab_billing/core/db/app_database.dart';
import 'package:xlab_billing/features/billing/cart_sheet.dart';
import 'package:xlab_billing/features/home_shell.dart';
import 'package:xlab_billing/localization/app_localizations.dart';
import 'package:xlab_billing/shared/controllers/app_state.dart';
import 'package:xlab_billing/shared/controllers/billing_state.dart';
import 'package:xlab_billing/shared/controllers/printer_state.dart';
import 'package:xlab_billing/shared/models/invoice.dart';
import 'package:xlab_billing/shared/models/product.dart';
import 'package:xlab_billing/shared/models/unit.dart';
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

  testWidgets('HomeShell renders the Billing tab shell', (WidgetTester tester) async {
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

    expect(find.byType(HomeShell), findsOneWidget);

    final fabFinder = find.byKey(const ValueKey('billing-cart-fab'));
    expect(fabFinder, findsOneWidget);
    final fabDisabled = tester.widget<FloatingActionButton>(fabFinder);
    expect(fabDisabled.onPressed, isNull);

    billing.addProduct(
      const Product(
        id: 1,
        nameEn: 'Momo',
        nameNe: '',
        sku: 'M1',
        descriptionEn: '',
        descriptionNe: '',
        ratePaisa: 15000,
        unitId: 1,
        category: 'food',
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      ),
      unit: const Unit(
        id: 1,
        nameEn: 'plate',
        nameNe: '',
        abbrevEn: 'plt',
        abbrevNe: '',
        isCustom: false,
      ),
    );
    await tester.pump();

    final fabEnabled = tester.widget<FloatingActionButton>(fabFinder);
    expect(fabEnabled.onPressed, isNotNull);
  });

  testWidgets('CartSheet renders items and inline charges/discount/tax/customer', (tester) async {
    final app = AppState();
    final billing = BillingController(app: app);
    billing.addProduct(
      const Product(
        id: 1,
        nameEn: 'Momo',
        nameNe: '',
        sku: 'M1',
        descriptionEn: '',
        descriptionNe: '',
        ratePaisa: 15000,
        unitId: 1,
        category: 'food',
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      ),
      unit: const Unit(
        id: 1,
        nameEn: 'plate',
        nameNe: '',
        abbrevEn: 'plt',
        abbrevNe: '',
        isCustom: false,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<BillingController>.value(value: billing),
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
          home: const Scaffold(body: CartSheet()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Momo'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsWidgets);
    expect(find.byIcon(Icons.add), findsWidgets);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    expect(find.byIcon(Icons.discount_outlined), findsOneWidget);
    expect(find.byIcon(Icons.receipt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.payments_outlined, skipOffstage: false), findsWidgets);
    expect(find.byIcon(Icons.person_outline, skipOffstage: false), findsOneWidget);

    // Verify payment method is on main cart page and functional
    expect(billing.paymentMethod, PaymentMethod.cash);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    await tester.tap(find.text('QR Payment', skipOffstage: false));
    await tester.pump();
    expect(billing.paymentMethod, PaymentMethod.qr);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.text('Grand Total', skipOffstage: false), findsOneWidget);
  });

  testWidgets('CartSheet inline charges update BillingController totals', (tester) async {
    final app = AppState();
    final billing = BillingController(app: app);
    billing.addProduct(
      const Product(
        id: 1,
        nameEn: 'Momo',
        nameNe: '',
        sku: 'M1',
        descriptionEn: '',
        descriptionNe: '',
        ratePaisa: 15000,
        unitId: 1,
        category: 'food',
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      ),
      unit: const Unit(
        id: 1,
        nameEn: 'plate',
        nameNe: '',
        abbrevEn: 'plt',
        abbrevNe: '',
        isCustom: false,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<BillingController>.value(value: billing),
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
          home: const Scaffold(body: CartSheet()),
        ),
      ),
    );
    await tester.pump();

    expect(billing.totals.grandTotal, 15000);

    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pump();

    final otherChargeField =
        find.widgetWithText(TextField, 'Other charges amount');
    expect(otherChargeField, findsOneWidget);
    await tester.enterText(otherChargeField, '50');
    await tester.pump();

    expect(billing.otherCharges, 5000);
    expect(billing.totals.grandTotal, 20000);
    // When no name is filled, it defaults to "Other Charges" in the summary row
    expect(find.text('Other Charges', skipOffstage: false), findsWidgets);

    // Overwrite the charge name
    final nameField = find.widgetWithText(TextField, 'Charge Name');
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Delivery');
    await tester.pump();

    expect(billing.otherChargesNote, 'Delivery');
    expect(find.widgetWithText(TextField, 'Delivery'), findsOneWidget);

    // Clear the name field again — should default back to "Other Charges"
    await tester.enterText(nameField, '');
    await tester.pump();

    expect(billing.otherChargesNote, '');
    expect(find.text('Delivery', skipOffstage: false), findsNothing);
    expect(find.text('Other Charges', skipOffstage: false), findsWidgets);
  });
}
